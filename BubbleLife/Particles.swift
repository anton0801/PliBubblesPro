import SwiftUI
import Combine

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var opacity: Double
    var size: CGFloat
    var color: Color
}

struct EnhancedParticleBackground: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var particles: [Particle] = []
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.darkViolet, .nearBlack, .deepPurple]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .rotationEffect(.degrees(particle.size * 10))
            }
        }
        .onReceive(timer) { _ in
            if dataManager.settings.animationsEnabled {
                updateParticles()
            }
        }
        .onAppear {
            for _ in 0..<30 {
                particles.append(Particle(
                    position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                     y: CGFloat.random(in: 0...UIScreen.main.bounds.height)),
                    velocity: CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: 1...4)),
                    opacity: Double.random(in: 0.3...0.8),
                    size: CGFloat.random(in: 4...8),
                    color: [Color.neonPink, .purpleGlow, .cyanGlow].randomElement()!
                ))
            }
        }
    }
    
    private func updateParticles() {
        particles = particles.map { particle in
            var newParticle = particle
            newParticle.position.y += newParticle.velocity.y
            newParticle.position.x += newParticle.velocity.x
            if newParticle.position.y > UIScreen.main.bounds.height {
                newParticle.position.y = 0
                newParticle.position.x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
                newParticle.opacity = Double.random(in: 0.3...0.8)
                newParticle.size = CGFloat.random(in: 4...8)
                newParticle.color = [Color.neonPink, .purpleGlow, .cyanGlow].randomElement()!
            }
            return newParticle
        }
    }
}
