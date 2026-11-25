import SceneKit
import SwiftUI

struct CinemaSurface: UIViewRepresentable {
    enum Mode {
        case chamber(CGFloat)
        case reveal(DrawReveal, CGPoint)
    }

    let mode: Mode

    func makeCoordinator() -> CinemaScene {
        switch mode {
        case .chamber:
            return CinemaScene(reveal: nil, origin: .init(x: 0.5, y: 0.65))
        case let .reveal(reveal, origin):
            return CinemaScene(reveal: reveal, origin: origin)
        }
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.camera
        view.antialiasingMode = .multisampling2X
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        view.backgroundColor = CinemaScene.void
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        switch mode {
        case .chamber:
            view.isPlaying = false
        case .reveal:
            view.rendersContinuously = true
            view.isPlaying = true
        }
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        if case let .chamber(charge) = mode {
            context.coordinator.poseChamber(Double(charge))
        }
    }
}

final class CinemaScene: NSObject, SCNSceneRendererDelegate {
    static let void = UIColor(red: 0.016, green: 0.029, blue: 0.071, alpha: 1)
    private static let gold = UIColor(red: 0.96, green: 0.69, blue: 0.33, alpha: 1)
    private static let cyan = UIColor(red: 0.28, green: 0.71, blue: 1, alpha: 1)
    private static let white = UIColor(red: 1, green: 0.97, blue: 0.87, alpha: 1)
    private static let cobalt = UIColor(red: 0.11, green: 0.29, blue: 0.64, alpha: 1)
    private static let steel = UIColor(red: 0.20, green: 0.29, blue: 0.45, alpha: 1)
    private static let reflectionMap = studioReflection()
    private static let ballArcs = [
        vector(-0.40, 0.65, 0.84), vector(0.34, 0.48, 0.38), vector(0.46, 0.29, 1.03),
        vector(-0.30, -0.33, 0.70), vector(-0.26, -0.48, 0.31), vector(0.53, -0.40, 0.92)
    ]


    let scene = SCNScene()
    let camera = SCNNode()

    private let reveal: DrawReveal?
    private let origin: CGPoint
    private let chamber = SCNNode()
    private let innerRing = SCNNode()
    private let seal = SCNNode()
    private let carrier = SCNNode()
    private let impactLight = SCNLight()
    private let rimLight = SCNLight()
    private let lens = SCNNode()
    private let wave = SCNNode()
    private var blades: [SCNNode] = []
    private var numberedBalls: [SCNNode] = []
    private var sparks: [SCNNode] = []
    private var flightLines: [SCNNode] = []

    init(reveal: DrawReveal?, origin: CGPoint) {
        self.reveal = reveal
        self.origin = origin
        super.init()
        scene.background.contents = Self.void
        scene.lightingEnvironment.contents = Self.reflectionMap
        scene.lightingEnvironment.intensity = 0.38
        buildCamera()
        buildLights()
        buildChamber()
        if let reveal {
            buildReveal(numbers: reveal.numbers)
            animate(elapsed: 0, aspect: 0.46)
        } else {
            poseChamber(0)
        }
    }

    func poseChamber(_ charge: Double) {
        poseCamera(x: -1.02, y: 0.72, z: 7.9 - charge * 0.29, target: vector(0, -0.55, 0), fov: 45)
        innerRing.eulerAngles.z = Float(-0.10 - charge * 0.31)
        impactLight.intensity = 92 + charge * 255
        rimLight.intensity = 220 + charge * 180
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let reveal else { return }
        let size = renderer.currentViewport.size
        let aspect = size.height > 0 ? size.width / size.height : 0.46
        animate(elapsed: max(0, Date().timeIntervalSince(reveal.start)), aspect: aspect)
    }

    private func buildCamera() {
        let optics = SCNCamera()
        optics.zNear = 0.025
        optics.zFar = 120
        optics.wantsHDR = true
        optics.wantsExposureAdaptation = false
        optics.bloomIntensity = 0.17
        optics.bloomThreshold = 1.24
        optics.bloomBlurRadius = 13
        optics.exposureOffset = -0.63
        camera.camera = optics
        scene.rootNode.addChildNode(camera)
    }

    private func buildLights() {
        addLight(.omni, color: Self.white, intensity: 570, at: vector(-2.9, 3.6, 5.0))
        addLight(.omni, color: Self.cyan, intensity: 295, at: vector(2.9, 1.8, 1.1))
        addLight(.ambient, color: UIColor(red: 0.49, green: 0.62, blue: 0.97, alpha: 1),
                 intensity: 107, at: vector(0, 0, 0))
        configureLight(impactLight, type: .omni, color: Self.gold, intensity: 92, at: vector(0, 0, 2.7))
        configureLight(rimLight, type: .omni, color: Self.cyan, intensity: 220, at: vector(0, -2.6, 1.4))
    }

    private func buildChamber() {
        let titanium = metal(Self.steel, roughness: 0.27)
        let enamel = metal(Self.cobalt, roughness: 0.33, amount: 0.67)
        let ebony = metal(Self.void, roughness: 0.40, amount: 0.65)
        let brass = metal(Self.gold, roughness: 0.26)
        let trimming = luminous(Self.gold, amount: 0.51)

        scene.rootNode.addChildNode(chamber)
        ring(radius: 2.22, tube: 0.13, z: 0.00, material: titanium, parent: chamber)
        ring(radius: 2.09, tube: 0.071, z: 0.082, material: enamel, parent: chamber)
        ring(radius: 2.23, tube: 0.022, z: 0.133, material: brass, parent: chamber)
        ring(radius: 1.92, tube: 0.077, z: 0.04, material: titanium, parent: chamber)
        ring(radius: 1.74, tube: 0.040, z: 0.10, material: brass, parent: chamber)
        ring(radius: 2.61, tube: 0.035, z: -0.25, material: enamel, parent: chamber)

        let backing = SCNCylinder(radius: 2.22, height: 0.16)
        backing.materials = [ebony]
        let plate = SCNNode(geometry: backing)
        plate.eulerAngles.x = .pi / 2
        plate.position.z = -0.47
        chamber.addChildNode(plate)

        chamber.addChildNode(innerRing)
        ring(radius: 1.57, tube: 0.06, z: 0.16, material: enamel, parent: innerRing)
        ring(radius: 1.52, tube: 0.023, z: 0.20, material: luminous(Self.cyan, amount: 0.24), parent: innerRing)
        ring(radius: 1.33, tube: 0.035, z: 0.09, material: brass, parent: innerRing)

        let scratch = SCNBox(width: 0.15, height: 0.015, length: 0.012, chamferRadius: 0.004)
        scratch.materials = [brass]
        let indicator = SCNBox(width: 0.20, height: 0.024, length: 0.016, chamferRadius: 0.006)
        indicator.materials = [trimming]
        for index in 0..<72 {
            let angle = Double(index) * .pi / 36
            let marker = SCNNode(geometry: index.isMultiple(of: 6) ? indicator : scratch)
            marker.position = vector(cos(angle) * 1.99, sin(angle) * 1.99, 0.13)
            marker.eulerAngles.z = Float(angle)
            chamber.addChildNode(marker)
        }

        let path = UIBezierPath()
        path.move(to: .init(x: 0.16, y: -0.20))
        path.addLine(to: .init(x: 0.82, y: -0.48))
        path.addLine(to: .init(x: 1.48, y: -0.22))
        path.addLine(to: .init(x: 1.50, y: 0.30))
        path.addQuadCurve(to: .init(x: 0.87, y: 0.60), controlPoint: .init(x: 1.24, y: 0.60))
        path.addLine(to: .init(x: 0.16, y: 0.20))
        path.close()
        let irisBlade = SCNShape(path: path, extrusionDepth: 0.095)
        irisBlade.chamferRadius = 0.035
        irisBlade.materials = [enamel, titanium, brass, brass, brass]
        for index in 0..<6 {
            let hinge = SCNNode()
            hinge.eulerAngles.z = Float(Double(index) * .pi / 3)
            let blade = SCNNode(geometry: irisBlade)
            blade.position = vector(0, 0, Double(index) * 0.005)
            hinge.addChildNode(blade)
            chamber.addChildNode(hinge)
            blades.append(blade)
        }
        let pearl = SCNSphere(radius: 0.37)
        pearl.segmentCount = 40
        pearl.materials = [metal(Self.white, roughness: 0.19, amount: 0.37, emission: Self.cyan, emissionAmount: 0.09)]
        seal.geometry = pearl
        seal.position.z = 0.38
        chamber.addChildNode(seal)
        buildBackdrop()
    }

    private func buildBackdrop() {
        let surround = SCNBox(width: 16, height: 18, length: 0.12, chamferRadius: 0)
        surround.materials = [metal(Self.void, roughness: 0.62, amount: 0.26)]
        let backdrop = SCNNode(geometry: surround)
        backdrop.position.z = -2.0
        scene.rootNode.addChildNode(backdrop)
        for index in 0..<3 {
            ring(radius: 3.03 + Double(index) * 0.59, tube: index == 0 ? 0.056 : 0.022,
                 z: -0.92 - Float(index) * 0.26,
                 material: metal(Self.steel, roughness: 0.38), parent: chamber)
        }
    }

    private func buildReveal(numbers: [Int]) {
        let shell = SCNSphere(radius: 0.55)
        shell.segmentCount = 48
        shell.materials = [metal(Self.white, roughness: 0.21, amount: 0.40, emission: Self.cyan, emissionAmount: 0.09)]
        carrier.geometry = shell
        scene.rootNode.addChildNode(carrier)

        let core = SCNSphere(radius: 0.24)
        core.materials = [luminous(Self.white, amount: 1.45)]
        lens.geometry = core
        lens.position = vector(0, 0, 0.65)
        scene.rootNode.addChildNode(lens)
        ring(radius: 1, tube: 0.027, z: 0, material: luminous(Self.gold, amount: 1.17), parent: wave)
        ring(radius: 0.86, tube: 0.014, z: -0.08, material: luminous(Self.cyan, amount: 0.74), parent: wave)
        wave.position = vector(0, 0, 0.65)
        scene.rootNode.addChildNode(wave)
        buildFlightLines()

        for number in numbers {
            let ball = makeNumberedBall(number)
            numberedBalls.append(ball)
            scene.rootNode.addChildNode(ball)
        }

        let shapes = (0..<4).map { index in
            let shard = SCNBox(width: 0.013 + CGFloat(index) * 0.004, height: 0.11 + CGFloat(index) * 0.032,
                               length: 0.017, chamferRadius: 0.006)
            shard.materials = [luminous(index.isMultiple(of: 2) ? Self.gold : Self.cyan, amount: 1.38)]
            return shard
        }
        for index in 0..<60 {
            let spark = SCNNode(geometry: shapes[index % shapes.count])
            sparks.append(spark)
            scene.rootNode.addChildNode(spark)
        }
    }

    private func buildFlightLines() {
        let cool = luminous(Self.cyan, amount: 0.46)
        let warm = luminous(Self.gold, amount: 0.58)
        let blue = SCNCylinder(radius: 0.010, height: 1.2)
        blue.radialSegmentCount = 5
        blue.materials = [cool]
        let gold = SCNCylinder(radius: 0.014, height: 1.2)
        gold.radialSegmentCount = 5
        gold.materials = [warm]
        for index in 0..<46 {
            let streak = SCNNode(geometry: index.isMultiple(of: 6) ? gold : blue)
            streak.eulerAngles.x = .pi / 2
            flightLines.append(streak)
            scene.rootNode.addChildNode(streak)
        }
    }

    private func makeNumberedBall(_ number: Int) -> SCNNode {
        let radius: CGFloat = 0.56
        let sphere = SCNSphere(radius: radius)
        sphere.segmentCount = 48
        let tint = Self.enamel(for: number)
        sphere.materials = [metal(tint, roughness: 0.28, amount: 0.44)]
        let ball = SCNNode(geometry: sphere)
        let motif = curvedBadge(radius: Float(radius) + 0.003)
        let label = SCNMaterial()
        label.diffuse.contents = Self.badge(number)
        label.lightingModel = .constant
        label.isDoubleSided = true
        // The curved square extends beyond the circular printed area.
        label.transparencyMode = .aOne
        motif.materials = [label]
        let front = SCNNode(geometry: motif)
        ball.addChildNode(front)
        return ball
    }

    private func animate(elapsed: Double, aspect: CGFloat) {
        let contact = LottoCutscene.collision
        let release = contact + LottoCutscene.impactHold
        let dive = segment(elapsed, from: 0, length: contact)
        let approach = pow(dive, 1.7)
        let recoil = easeOut(segment(elapsed, from: release, length: 0.69))
        let swing = sin(.pi * dive)
        let jolt = segment(elapsed, from: release, length: 0.23)
        let shake = sin(jolt * .pi * 4) * pow(1 - jolt, 3)
        let opening = easeOut(segment(elapsed, from: release, length: 0.39))
        let pulse = glow(elapsed, at: contact, decay: 11)
        let finale = glow(elapsed, at: 1.02, decay: 12)
        let squeeze = min(1, Double(aspect) / 0.47)

        poseCamera(x: -0.83 + 1.59 * swing + 0.62 * approach + 0.11 * shake,
                   y: 0.55 + 0.53 * swing - 0.53 * approach + 0.15 * recoil,
                   z: 7.65 - 4.27 * approach + 6.69 * recoil + 0.16 * shake,
                   target: vector(0, -0.48 + 0.64 * approach - 0.31 * recoil, 0.05),
                   fov: 48 + 32 * approach - 24 * recoil,
                   roll: 0.10 * swing - 0.018 * shake)
        chamber.eulerAngles.z = Float(-0.08 + 0.18 * approach - 0.17 * recoil)
        innerRing.eulerAngles.z = Float(0.06 + 1.28 * opening)
        impactLight.intensity = 95 + 530 * pulse + 168 * finale
        rimLight.intensity = 220 + 229 * opening
        seal.opacity = CGFloat(1 - segment(elapsed, from: 0.06, length: 0.14))
        for (index, blade) in blades.enumerated() {
            let start = release + 0.014 * Double(index % 3)
            let move = easeOut(segment(elapsed, from: start, length: 0.30))
            blade.position.x = Float(move * 0.76)
            blade.eulerAngles.z = Float(-move * 0.31)
        }

        poseCarrier(elapsed)
        poseFlightLines(elapsed)
        poseImpact(elapsed: elapsed, pulse: pulse, finale: finale)
        for (index, ball) in numberedBalls.enumerated() {
            poseBall(ball, index: index, elapsed: elapsed, squeeze: squeeze)
        }
        poseSparks(elapsed)
    }

    private func poseCarrier(_ elapsed: Double) {
        let travel = segment(elapsed, from: 0, length: LottoCutscene.collision)
        let advance = 0.24 * travel + 0.76 * travel * travel
        carrier.isHidden = elapsed >= LottoCutscene.collision + LottoCutscene.impactHold
        let x = Double(origin.x - 0.5) * 2.4 * (1 - advance) + sin(.pi * travel) * 0.34
        let y = -Double(origin.y - 0.5) * 5.5 * (1 - advance)
        carrier.position = vector(x, y, 2.29 - advance * 2.04)
        let scale = 0.73 - advance * 0.38
        carrier.scale = vector(scale, scale, scale)
    }

    private func poseFlightLines(_ elapsed: Double) {
        let end = LottoCutscene.collision + LottoCutscene.impactHold
        let flight = segment(elapsed, from: 0.015, length: LottoCutscene.collision - 0.015)
        let fade = 1 - segment(elapsed, from: end, length: 0.11)
        let past = flight * flight
        for (index, line) in flightLines.enumerated() {
            line.isHidden = flight == 0 || fade == 0
            let angle = Double(index) * 2.39996
            let seed = Double((index * 29 + 7) % 53) / 53
            let radius = 1.45 + seed * 2.58
            let depth = -1.35 + Double(index % 7) * 0.54 + past * (1.5 + seed)
            line.position = vector(cos(angle) * radius, sin(angle) * radius, depth)
            line.scale.y = Float(0.40 + past * (0.67 + seed))
            line.opacity = CGFloat(min(1, flight * 2.8) * fade * (0.34 + seed * 0.60))
        }
    }

    private func poseImpact(elapsed: Double, pulse: Double, finale: Double) {
        let transient = max(pulse, finale * 0.44)
        lens.opacity = CGFloat(transient)
        let flareScale = 0.40 + segment(elapsed, from: LottoCutscene.collision, length: 0.17) * 2.03
        lens.scale = vector(flareScale * 1.29, flareScale * 0.66, flareScale * 0.30)
        let start = elapsed < 1.02 ? LottoCutscene.collision : 1.02
        let response = segment(elapsed, from: start, length: 0.56)
        let radius = 0.22 + easeOut(response) * 4.65
        wave.scale = vector(radius, radius, 0.44)
        wave.opacity = CGFloat(pow(1 - response, 2) * transient)
    }

    private func poseBall(_ ball: SCNNode, index: Int, elapsed: Double, squeeze: Double) {
        let delay = LottoCutscene.firstBall + LottoCutscene.ballInterval * Double(index)
        let phase = segment(elapsed, from: delay, length: LottoCutscene.ballFlight)
        ball.isHidden = elapsed < delay
        let travel = easeOut(phase)
        let arc = sin(phase * .pi) * pow(1 - phase, 0.45)
        let side = Double(index % 3 - 1)
        let row = index < 3 ? 0.78 : -0.43
        let bow = Self.ballArcs[index]
        let rebound = sin(phase * .pi * 2.6) * pow(1 - phase, 2) * 0.12

        ball.position = vector((side * 1.28 * travel + Double(bow.x) * arc) * squeeze,
                               (row + abs(side) * 0.11) * travel + Double(bow.y) * arc - rebound,
                               -0.12 + travel * 1.63 + Double(bow.z) * arc)
        ball.eulerAngles = vector(Double(bow.y) * 2.25 * (1 - phase),
                                  -Double(bow.x) * 2.14 * (1 - phase),
                                  Double(bow.x) * 0.85 * (1 - travel))
        let scale = (0.33 + 0.67 * travel + 0.12 * arc) * squeeze
        ball.scale = vector(scale, scale, scale)
    }

    private func poseSparks(_ elapsed: Double) {
        for (index, spark) in sparks.enumerated() {
            let start = index.isMultiple(of: 3) ? 1.02 : LottoCutscene.collision
            let age = segment(elapsed, from: start, length: 0.68)
            spark.isHidden = elapsed < start || age >= 1
            let angle = Double(index) * 2.39996
            let variation = Double((index * 31 + 9) % 61) / 61
            let spread = (0.23 + easeOut(age) * (1.4 + 2.55 * variation))
            spark.position = vector(cos(angle) * spread, sin(angle) * spread,
                                    0.28 + variation * (0.61 + age * 3.45))
            spark.eulerAngles.z = Float(angle - .pi / 2)
            spark.opacity = CGFloat(pow(1 - age, 1.6))
        }
    }

    private func poseCamera(x: Double, y: Double, z: Double, target: SCNVector3, fov: Double, roll: Double = 0) {
        camera.position = vector(x, y, z)
        // An absolute up direction keeps the temporary launch tilt from accumulating frame by frame.
        camera.look(at: target, up: vector(-sin(roll), cos(roll), 0), localFront: vector(0, 0, -1))
        camera.camera?.fieldOfView = CGFloat(fov)
    }

    private func ring(radius: CGFloat, tube: CGFloat, z: Float, material: SCNMaterial, parent: SCNNode) {
        let torus = SCNTorus(ringRadius: radius, pipeRadius: tube)
        torus.ringSegmentCount = 96
        torus.pipeSegmentCount = 9
        torus.materials = [material]
        let node = SCNNode(geometry: torus)
        node.eulerAngles.x = .pi / 2
        node.position.z = z
        parent.addChildNode(node)
    }

    private func metal(_ color: UIColor, roughness: Double, amount: Double = 0.86,
                       emission: UIColor? = nil, emissionAmount: CGFloat = 0) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = color
        material.metalness.contents = amount
        material.roughness.contents = roughness
        material.emission.contents = emission
        material.emission.intensity = emissionAmount
        return material
    }

    private func luminous(_ color: UIColor, amount: CGFloat = 1.0) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        material.emission.contents = color
        material.emission.intensity = amount
        return material
    }

    private func addLight(_ type: SCNLight.LightType, color: UIColor, intensity: CGFloat, at position: SCNVector3) {
        configureLight(SCNLight(), type: type, color: color, intensity: intensity, at: position)
    }

    private func configureLight(_ light: SCNLight, type: SCNLight.LightType, color: UIColor,
                                intensity: CGFloat, at position: SCNVector3) {
        light.type = type
        light.color = color
        light.intensity = intensity
        light.attenuationStartDistance = 0.4
        light.attenuationEndDistance = 12
        let node = SCNNode()
        node.position = position
        node.light = light
        scene.rootNode.addChildNode(node)
    }

    private func curvedBadge(radius: Float) -> SCNGeometry {
        let segments = 14
        let half: Float = 0.334
        var vertices: [SCNVector3] = []
        var texels: [CGPoint] = []
        var triangles: [UInt16] = []
        for y in 0...segments {
            for x in 0...segments {
                let u = Float(x) / Float(segments)
                let v = Float(y) / Float(segments)
                let dx = (u - 0.5) * half * 2
                let dy = (v - 0.5) * half * 2
                let dz = sqrt(max(0, radius * radius - dx * dx - dy * dy))
                vertices.append(SCNVector3(dx, dy, dz))
                texels.append(CGPoint(x: CGFloat(u), y: CGFloat(1 - v)))
                if x < segments, y < segments {
                    let a = UInt16(y * (segments + 1) + x)
                    let b = a + UInt16(segments + 1)
                    triangles += [a, a + 1, b, b, a + 1, b + 1]
                }
            }
        }
        let normals = vertices.map { SCNVector3($0.x / radius, $0.y / radius, $0.z / radius) }
        let topology = SCNGeometryElement(indices: triangles, primitiveType: .triangles)
        return SCNGeometry(sources: [.init(vertices: vertices), .init(normals: normals), .init(textureCoordinates: texels)],
                           elements: [topology])
    }

    private static func enamel(for number: Int) -> UIColor {
        switch number {
        case 1...10: UIColor(red: 0.68, green: 0.36, blue: 0.11, alpha: 1)
        case 11...20: UIColor(red: 0.25, green: 0.24, blue: 0.58, alpha: 1)
        case 21...30: UIColor(red: 0.70, green: 0.25, blue: 0.20, alpha: 1)
        case 31...40: UIColor(red: 0.13, green: 0.37, blue: 0.64, alpha: 1)
        default: UIColor(red: 0.23, green: 0.53, blue: 0.47, alpha: 1)
        }
    }

    private static func badge(_ number: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 384, height: 384), format: format).image { ctx in
            let circle = CGRect(x: 19, y: 19, width: 346, height: 346)
            white.setFill()
            ctx.cgContext.fillEllipse(in: circle)
            gold.withAlphaComponent(0.74).setStroke()
            ctx.cgContext.setLineWidth(4)
            ctx.cgContext.strokeEllipse(in: circle.insetBy(dx: 12, dy: 12))

            let type = UIFont.systemFont(ofSize: 170, weight: .black)
            let font = UIFont(descriptor: type.fontDescriptor.withDesign(.rounded) ?? type.fontDescriptor, size: 170)
            let label = NSAttributedString(string: String(format: "%02d", number), attributes: [
                .font: font, .foregroundColor: UIColor(red: 0.039, green: 0.09, blue: 0.19, alpha: 1)
            ])
            let size = label.size()
            label.draw(at: .init(x: (384 - size.width) / 2, y: (384 - size.height) / 2 - 2))
        }
    }

    private static func studioReflection() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: .init(width: 512, height: 256), format: format).image { image in
            let ctx = image.cgContext
            void.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 512, height: 256))
            let lights: [(CGPoint, CGFloat, UIColor)] = [
                (.init(x: 105, y: 82), 78, white),
                (.init(x: 340, y: 88), 92, cyan),
                (.init(x: 202, y: 143), 59, gold),
                (.init(x: 453, y: 40), 50, UIColor(white: 0.8, alpha: 1))
            ]
            for (center, radius, color) in lights {
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                          colors: [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray,
                                          locations: [0, 1])!
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 6,
                                       endCenter: center, endRadius: radius, options: [])
            }
            white.withAlphaComponent(0.74).setFill()
            ctx.fill(.init(x: 61, y: 54, width: 61, height: 16))
            ctx.fill(.init(x: 314, y: 45, width: 10, height: 85))
        }
    }
}

private func vector(_ x: Double, _ y: Double, _ z: Double) -> SCNVector3 {
    SCNVector3(Float(x), Float(y), Float(z))
}

private func segment(_ value: Double, from start: Double, length: Double) -> Double {
    min(1, max(0, (value - start) / length))
}

private func easeOut(_ value: Double) -> Double { 1 - pow(1 - value, 3) }

private func glow(_ value: Double, at start: Double, decay: Double) -> Double {
    guard value >= start else { return 0 }
    return exp(-(value - start) * decay)
}
