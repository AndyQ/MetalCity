import func Foundation.log10f


private let VELOCITY: Float         = 0.3
private let GRAVITY: Float          = -0.08

private let COLORS: [Color4] = [
    Color4(r: 1.0, g: 0.0, b: 0.0, a: 1.0),
    Color4(r: 0.0, g: 1.0, b: 0.0, a: 1.0),
    Color4(r: 1.0, g: 1.0, b: 0.0, a: 1.0),
    Color4(r: 0.0, g: 1.0, b: 1.0, a: 1.0),
    Color4(r: 1.0, g: 0.0, b: 0.5, a: 1.0),
    Color4(r: 1.0, g: 0.0, b: 1.0, a: 1.0),
    Color4(r: 1.0, g: 0.2, b: 0.2, a: 1.0),
]

// Return distance traveled
// Simulate air drag - velocity tapers off exponentially
private func _get_flight(vel: Float, secs: Float) -> Float {
    let t = log10f(1 + secs * 10.0)
    return t * vel
}


// A single projectile / point of light
// We record its initial parameters, so later we can (re)calculate position at
// any point in time.  Note the entire struct is immutable.
struct Flare {
    let velocity_vec: Vector3
    let size: Float
    let color: Color4

    // How long the light lasts
    let duration_secs: Float

    // How far back the trail goes (plume mode)
    let trail_secs: Float

    func point(at secs: Float, orig_pos: Vector3) -> Vector3 {
        var ret = orig_pos
        ret.x += _get_flight(vel: velocity_vec.x, secs: secs)
        ret.y += _get_flight(vel: velocity_vec.y, secs: secs)
        ret.z += _get_flight(vel: velocity_vec.z, secs: secs)

        // Gravity
        ret.y += (GRAVITY / Float(2.0) * secs * secs)

        return ret
    }

    func color(at secs: Float) -> Color4 {
        // Linear fade out is fine.  Note we can start with a > 1.0,
        // so it actually appears exponential.
        let percent = secs / duration_secs
        var ret = color
        ret.a *= (1 - percent)
        return ret
    }
}


class Firework: Drawable {
    let pos: Vector3
    let start_time: Int64
    let type: Int
    var m_flares = [Flare]()

    // Create a random firework
    init(time: Int64) { //}, aspect_x: Float) {
        let pos_x = random_range(lower:0.0, 512.0)
        let pos_y = random_range(lower:80.0, 125.0)
        let pos_z = random_range(lower:0.0, 512.0)

        self.pos = Vector3(x: pos_x, y: pos_y, z: pos_z)
        self.type = random_range(lower:0, 1)
        self.start_time = time

        self.add_flares()
    }

    private func add_flares() {
        let count = 400
        let orig_color = COLORS.randomElement()!

        // Reserve exact storage space.  It saves a bit of wasted memory.
        m_flares.reserveCapacity(count)

        for _ in 0..<count {
            var velocity = RandomUniformUnitVector()


            // velocity variance
            let speed_variance = random_range(lower:40.0, 50.0)
            velocity.x *= VELOCITY * speed_variance
            velocity.y *= VELOCITY * speed_variance
            velocity.z *= VELOCITY * speed_variance

            // color variance
            var color = orig_color
            color.r += random_range(lower:-0.3, 0.3)
            color.b += random_range(lower:-0.3, 0.3)
            color.g += random_range(lower:-0.3, 0.3)
            color.a = random_range(lower:0.7, 4.0)

            // other variance
            let duration_secs = random_range(lower:0.5, 3.0)
            let trail_secs = random_range(lower:0.3, 0.7)
            let size = random_range(lower:0.06, 0.5)

            let f = Flare(velocity_vec: velocity,
                        size: size,
                        color: color,
                        duration_secs: duration_secs,
                        trail_secs: trail_secs)
            m_flares.append(f)
        }
    }

    func secondsElapsed(time: Int64) -> Float {
        if time < start_time {
            return 0
        }
        return Float(time - start_time) / 1_000_000
    }

    func draw(time: Int64,
              bv: inout BufferWrapper,
              bc: inout BufferWrapper) {
        let secs = self.secondsElapsed(time: time)
        if self.type == 0 {
            // classic particle only
            for flare in self.m_flares {
                render_flare_simple(flare: flare, secs: secs, bv: &bv, bc: &bc)
            }
        } else {
            // long trail
            for flare in self.m_flares {
                render_flare_trail(flare: flare, secs: secs, bv: &bv, bc: &bc)
            }
        }
    }

    @inline(never)
    func render_flare_simple(flare: Flare, secs: Float,
                             bv: inout BufferWrapper, bc: inout BufferWrapper)
    {
        if secs > flare.duration_secs {
            return
        }
        let p = flare.point(at: secs, orig_pos: self.pos)
        var color = flare.color(at: secs)
        if secs > (flare.duration_secs - 0.1) {
            // flash out
            color.a = 1.0
        }
        let size = flare.size
        draw_triangle_2d(b:&bv, p, width: size, height: size)
        draw_triangle_color(b:&bc, color)
        draw_triangle_2d(b:&bv, p, width: size, height: -size)
        draw_triangle_color(b:&bc, color)
    }

    @inline(never)
    func render_flare_trail(flare: Flare, secs: Float,
                            bv: inout BufferWrapper, bc: inout BufferWrapper)
    {
        // If this is too small, flickering happens when the dots move
        let PLUME_STEP_SECS: Float  = 0.02

        var secs = secs
        if secs > flare.duration_secs {
            return
        }
        var color = flare.color(at: secs)
        var plume_secs = Float(0)
        var size = flare.size
        var first = true

        while true {
            let p = flare.point(at: secs, orig_pos: self.pos)
            draw_triangle_2d(b:&bv, p, width: size, height: size)
            draw_triangle_color(b:&bc, color)
            if first {
                draw_triangle_2d(b:&bv, p, width: size, height: -size)
                draw_triangle_color(b:&bc, color)
                first = false
            }

            size *= 0.95
            color.a *= 0.90
            secs -= PLUME_STEP_SECS
            plume_secs += PLUME_STEP_SECS
            if secs < 0 || plume_secs > flare.trail_secs {
                return
            }
        }
    }
}


private func draw_triangle_2d(b: inout BufferWrapper,
        _ pos: Vector3, width: Float, height: Float) {
    guard b.has_available(len: 24) else { return }

    b.append_raw(v: pos.x - width)
    b.append_raw(v: pos.y)
    b.append_raw(v: pos.z)
    b.append_raw(v: 1.0)

    b.append_raw(v: pos.x + width)
    b.append_raw(v: pos.y)
    b.append_raw(v: pos.z)
    b.append_raw(v: 1.0)

    b.append_raw(v: pos.x)
    b.append_raw(v: pos.y + height)
    b.append_raw(v: pos.z)
    b.append_raw(v: 1.0)

    // Do cross triangle
    b.append_raw(v: pos.x)
    b.append_raw(v: pos.y)
    b.append_raw(v: pos.z - width)
    b.append_raw(v: 1.0)

    b.append_raw(v: pos.x)
    b.append_raw(v: pos.y)
    b.append_raw(v: pos.z + width)
    b.append_raw(v: 1.0)

    b.append_raw(v: pos.x)
    b.append_raw(v: pos.y + height)
    b.append_raw(v: pos.z)
    b.append_raw(v: 1.0)
}


private func draw_triangle_color(b: inout BufferWrapper, _ color: Color4) {
    guard b.has_available(len: 24) else {
        return
    }

    b.append_raw_color4(v: color)
    b.append_raw_color4(v: color)
    b.append_raw_color4(v: color)

    b.append_raw_color4(v: color)
    b.append_raw_color4(v: color)
    b.append_raw_color4(v: color)
}
