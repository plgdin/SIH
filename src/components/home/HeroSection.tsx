import { Link } from 'react-router-dom';
import { ArrowRight } from 'lucide-react';
import { useEffect, useRef, useState, useCallback, lazy, Suspense } from 'react';

const GLSLHills = lazy(() => import('../ui/glsl-hills').then(m => ({ default: m.GLSLHills })));

/**
 * HeroSection with scroll-driven logo animation.
 * 
 * The "lelam.co" text in the hero animates smoothly into the navbar logo
 * position as the user scrolls. Colors transition from white (hero) to
 * the dark brand color (navbar) during the animation.
 */
export function HeroSection() {
  const heroRef = useRef<HTMLDivElement>(null);
  const [scrollProgress, setScrollProgress] = useState(0);
  const [showHills, setShowHills] = useState(false);
  const heroHeightRef = useRef<number>(0);
  const scrollFrameRef = useRef<number | null>(null);

  // Cache hero offsetHeight to prevent layout thrashing and forced reflows on scroll
  const measureHeight = useCallback(() => {
    if (heroRef.current) {
      heroHeightRef.current = heroRef.current.offsetHeight;
    }
  }, []);

  const handleScroll = useCallback(() => {
    if (scrollFrameRef.current !== null) return;
    scrollFrameRef.current = requestAnimationFrame(() => {
      scrollFrameRef.current = null;
      const heroHeight = heroHeightRef.current;
      if (!heroHeight) return;
      const scrollY = window.scrollY;
      const progress = Math.min(Math.max(scrollY / (heroHeight * 0.7), 0), 1);
      setScrollProgress(progress);
    });
  }, []);

  useEffect(() => {
    // WebGL is purely decorative background. Start it after the initial
    // paint and idle window so it never competes with FCP, LCP, or input readiness.
    let started = false;
    const start = () => {
      if (started) return;
      started = true;
      setShowHills(true);
      window.removeEventListener('pointerdown', start);
      window.removeEventListener('scroll', start);
      window.removeEventListener('touchstart', start);
    };

    const timer = window.setTimeout(start, 2500);
    window.addEventListener('pointerdown', start, { once: true, passive: true });
    window.addEventListener('scroll', start, { once: true, passive: true });
    window.addEventListener('touchstart', start, { once: true, passive: true });

    return () => {
      clearTimeout(timer);
      window.removeEventListener('pointerdown', start);
      window.removeEventListener('scroll', start);
      window.removeEventListener('touchstart', start);
      if (scrollFrameRef.current !== null) cancelAnimationFrame(scrollFrameRef.current);
    };
  }, []);

  useEffect(() => {
    // Initial measurement
    measureHeight();

    const handleResize = () => {
      measureHeight();
      handleScroll();
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('resize', handleResize);

    // Recalculate once DOM is fully painted
    const handle = requestAnimationFrame(() => {
      measureHeight();
      handleScroll();
    });

    return () => {
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('resize', handleResize);
      cancelAnimationFrame(handle);
    };
  }, [handleScroll, measureHeight]);

  // Dispatch custom event so Header knows hero scroll state
  useEffect(() => {
    window.dispatchEvent(new CustomEvent('hero-scroll-progress', { detail: scrollProgress }));
  }, [scrollProgress]);

  // Announce hero is mounted/unmounted
  useEffect(() => {
    window.dispatchEvent(new CustomEvent('hero-mount', { detail: true }));
    return () => {
      window.dispatchEvent(new CustomEvent('hero-mount', { detail: false }));
    };
  }, []);

  return (
    <div ref={heroRef} className="relative overflow-hidden -mt-[81px] min-h-[calc(100dvh+81px)] pt-12 pb-48 sm:pt-[193px] sm:pb-60 lg:pt-[225px] lg:pb-72 flex flex-col justify-center items-center text-center bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950">
      {/* GLSL Hills Background */}
      <div className="absolute inset-0 z-0 pointer-events-none" style={{ opacity: 0.75 * (1 - scrollProgress) }}>
        {showHills && (
          <Suspense fallback={null}>
            <GLSLHills width="100%" height="100%" />
          </Suspense>
        )}
      </div>

      {/* Simple dark overlay */}
      <div className="absolute inset-0 z-0 overflow-hidden pointer-events-none">
        <div className="absolute inset-0 bg-gradient-to-r from-slate-950/20 to-slate-900/20 mix-blend-multiply" />
      </div>

      <div className="relative z-10 w-full px-4 sm:px-8 lg:px-12 flex flex-col items-center">
        <div className="max-w-4xl flex flex-col items-center">
          {/* Main Title */}
          <h1 className="text-3xl sm:text-5xl md:text-6xl lg:text-7xl font-black tracking-tight text-white mb-8 sm:mb-10 text-center leading-tight uppercase" style={{
            opacity: 1 - scrollProgress * 1.3,
            transform: `translateY(${-scrollProgress * 30}px)`,
          }}>
            Where auctions are mainstream
          </h1>

          {/* CTA */}
          <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 w-full sm:w-auto px-4 sm:px-0" style={{
            opacity: 1 - scrollProgress * 1.5,
            transform: `translateY(${-scrollProgress * 20}px)`,
          }}>
            <Link
              to="/auctions"
              className="group inline-flex items-center justify-center px-8 sm:px-10 py-4 sm:py-5 text-base sm:text-lg font-semibold rounded-2xl text-white bg-primary hover:bg-primary-700 active:bg-primary-800 transition-all duration-300 shadow-xl shadow-primary/30 hover:shadow-primary/60 hover:-translate-y-0.5 cursor-pointer w-full sm:w-auto"
            >
              Explore Auctions
              <ArrowRight className="ml-2 w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </Link>
          </div>
        </div>
      </div>



    </div>
  );
}
