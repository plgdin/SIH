import { Link, Outlet, useLocation } from 'react-router-dom';
import { PageTracker } from '../components/common/PageTracker';
import { CookieConsent } from '../components/common/CookieConsent';
import clsx from 'clsx';

export function AuthLayout() {
  const location = useLocation();
  const subtitlePhrase = 'Everything you need in a single platform.';
  const isRegister = location.pathname.includes('/register') || location.pathname.includes('/signup');

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col justify-between relative overflow-x-hidden font-sans">
      <PageTracker />
      
      {/* Background ambient glow effect */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-7xl h-96 bg-gradient-to-b from-primary/20 via-primary/5 to-transparent blur-3xl pointer-events-none z-0" />

      {/* Main Split Layout */}
      <div className="flex-1 grid grid-cols-1 md:grid-cols-2 relative z-10">

        {/* Branding Column (Left - Desktop only) */}
        <div className="hidden md:flex bg-slate-900/90 backdrop-blur-xl relative overflow-hidden flex-col justify-between p-12 lg:p-16 text-white border-r border-slate-800/60">
          <div className="absolute inset-0 z-0">
            <div className="absolute inset-0 bg-gradient-to-br from-slate-950 via-slate-900 to-primary-950 mix-blend-multiply" />
            <div className="absolute inset-y-0 right-0 w-1/2 bg-gradient-to-l from-primary-800/10 to-transparent" />
          </div>

          <div className="relative z-10 flex-1 flex flex-col items-center justify-center text-center">
            <p className="text-xl lg:text-2xl font-bold text-slate-200 max-w-md leading-relaxed">
              {subtitlePhrase}
            </p>
          </div>

          <div className="relative z-10 flex justify-between items-center border-t border-slate-800/50 pt-6 mt-6">
            <div className="flex gap-1.5 items-center">
              <span
                className={clsx(
                  "h-1.5 rounded-full transition-all duration-500 ease-in-out",
                  !isRegister ? "w-8 bg-primary shadow-sm" : "w-4 bg-slate-700"
                )}
              />
              <span className="w-4 h-1.5 rounded-full bg-slate-700" />
              <span
                className={clsx(
                  "h-1.5 rounded-full transition-all duration-500 ease-in-out",
                  isRegister ? "w-8 bg-primary shadow-sm" : "w-4 bg-slate-700"
                )}
              />
            </div>
          </div>
        </div>

        {/* Form Column (Right / Center on Mobile & Tablet) */}
        <div className="bg-white flex flex-col justify-center items-center py-8 sm:py-12 px-4 sm:px-6 md:px-10 lg:px-16 min-h-[calc(100vh-60px)] md:min-h-0">
          <div className="w-full max-w-sm sm:max-w-md">
            <Outlet />
          </div>
        </div>
      </div>

      <CookieConsent />
    </div>
  );
}
