// Three.js-inspired Modern 3D Ambient Canvas Effect (Pure Canvas, 60fps, Zero-overhead)
export class AmbientAtmosphere {
  constructor(canvasId = 'ambient-canvas') {
    this.canvas = document.getElementById(canvasId);
    if (!this.canvas) return;
    this.ctx = this.canvas.getContext('2d');
    this.particles = [];
    this.numParticles = 48;
    this.mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.dpr = Math.min(window.devicePixelRatio || 1, 2);
    this.isTimerActive = false;
    this.isGoldenGate = false;
    this.time = 0;

    this.init();
  }

  init() {
    this.resize();
    window.addEventListener('resize', () => this.resize(), { passive: true });
    window.addEventListener('mousemove', (e) => {
      this.mouse.targetX = (e.clientX - this.width / 2) * 0.05;
      this.mouse.targetY = (e.clientY - this.height / 2) * 0.05;
    }, { passive: true });

    // Spawn 3D ambient particles
    for (let i = 0; i < this.numParticles; i++) {
      this.particles.push({
        x: (Math.random() - 0.5) * this.width * 1.4,
        y: (Math.random() - 0.5) * this.height * 1.4,
        z: Math.random() * 800 + 100, // Depth
        radius: Math.random() * 2.2 + 0.8,
        color: i % 3 === 0 ? '#F0C987' : (i % 3 === 1 ? '#60A5FA' : '#10B981'),
        alpha: Math.random() * 0.5 + 0.2,
        speedX: (Math.random() - 0.5) * 0.35,
        speedY: (Math.random() - 0.5) * 0.35,
        pulseSpeed: Math.random() * 0.02 + 0.01,
        phase: Math.random() * Math.PI * 2
      });
    }

    this.animate();
  }

  resize() {
    this.width = window.innerWidth;
    this.height = window.innerHeight;
    this.canvas.width = this.width * this.dpr;
    this.canvas.height = this.height * this.dpr;
    this.canvas.style.width = `${this.width}px`;
    this.canvas.style.height = `${this.height}px`;
    this.ctx.scale(this.dpr, this.dpr);
  }

  setTimerState(isRunning, isGolden) {
    this.isTimerActive = isRunning;
    this.isGoldenGate = isGolden;
  }

  animate() {
    requestAnimationFrame(() => this.animate());
    this.time += 0.02;

    // Smooth mouse lerp (3D camera drift)
    this.mouse.x += (this.mouse.targetX - this.mouse.x) * 0.06;
    this.mouse.y += (this.mouse.targetY - this.mouse.y) * 0.06;

    this.ctx.clearRect(0, 0, this.width, this.height);

    const cx = this.width / 2;
    const cy = this.height / 2;

    // 1. Dynamic Luminous Aura / Radial Nebulae (Breathes gently during focus)
    const breathScale = this.isTimerActive ? Math.sin(this.time * 0.8) * 0.15 + 1.0 : 1.0;
    
    // Top-Center Warm Sun / Gold Halo
    const grad1 = this.ctx.createRadialGradient(
      cx + this.mouse.x * 2, 
      cy * 0.35 + this.mouse.y * 2, 
      10,
      cx + this.mouse.x * 2, 
      cy * 0.35 + this.mouse.y * 2, 
      Math.max(cx, cy) * 0.75 * breathScale
    );
    if (this.isGoldenGate) {
      grad1.addColorStop(0, 'rgba(16, 185, 129, 0.16)');
      grad1.addColorStop(0.5, 'rgba(240, 201, 135, 0.08)');
      grad1.addColorStop(1, 'transparent');
    } else {
      grad1.addColorStop(0, 'rgba(240, 201, 135, 0.12)');
      grad1.addColorStop(0.6, 'rgba(217, 119, 6, 0.03)');
      grad1.addColorStop(1, 'transparent');
    }
    this.ctx.fillStyle = grad1;
    this.ctx.fillRect(0, 0, this.width, this.height);

    // Bottom-Right Deep Cosmic Tint
    const grad2 = this.ctx.createRadialGradient(
      this.width * 0.8 - this.mouse.x,
      this.height * 0.85 - this.mouse.y,
      20,
      this.width * 0.8 - this.mouse.x,
      this.height * 0.85 - this.mouse.y,
      Math.max(cx, cy) * 0.6
    );
    grad2.addColorStop(0, 'rgba(96, 165, 250, 0.07)');
    grad2.addColorStop(1, 'transparent');
    this.ctx.fillStyle = grad2;
    this.ctx.fillRect(0, 0, this.width, this.height);

    // 2. Render 3D Perspective Stardust Particles
    const fov = 400; // Focal length

    for (let p of this.particles) {
      p.x += p.speedX;
      p.y += p.speedY;

      // Wrap-around in 3D box
      if (p.x < -this.width * 0.7) p.x = this.width * 0.7;
      if (p.x > this.width * 0.7) p.x = -this.width * 0.7;
      if (p.y < -this.height * 0.7) p.y = this.height * 0.7;
      if (p.y > this.height * 0.7) p.y = -this.height * 0.7;

      // Perspective projection
      const projectedX = cx + ((p.x - this.mouse.x * 4) * fov) / (p.z + fov);
      const projectedY = cy + ((p.y - this.mouse.y * 4) * fov) / (p.z + fov);
      const scale = fov / (p.z + fov);
      const currentRadius = p.radius * scale * (Math.sin(this.time + p.phase) * 0.3 + 1);

      if (projectedX >= -20 && projectedX <= this.width + 20 && projectedY >= -20 && projectedY <= this.height + 20) {
        this.ctx.beginPath();
        this.ctx.arc(projectedX, projectedY, Math.max(0.5, currentRadius), 0, Math.PI * 2);
        this.ctx.fillStyle = p.color;
        this.ctx.globalAlpha = p.alpha * scale;
        this.ctx.fill();
        this.ctx.globalAlpha = 1.0;
      }
    }
  }
}
