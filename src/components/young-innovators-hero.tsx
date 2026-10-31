import { ArrowRight, CalendarDays, GraduationCap, Lightbulb, Trophy, Users, Rocket, Video } from 'lucide-react';
import { Button } from '@/components/ui/button';
import hero from '@/assets/young-innovators-hero-2026.jpg';

export function YoungInnovatorsHero() {
  return <>
    <section className="young-challenge-hero relative isolate overflow-hidden border-b border-border">
      <img src={hero} width={1920} height={1024} alt="Indian school students developing a robot with a glowing innovation lightbulb" fetchPriority="high" className="absolute inset-0 h-full w-full object-cover" />
      <div className="young-challenge-shade absolute inset-0" aria-hidden="true" />
      <div className="relative mx-auto max-w-[1380px] px-5 py-10 sm:px-6 lg:px-12 lg:py-12">
        <div className="young-hero-copy max-w-[620px]">
          <p className="text-xs font-bold uppercase">Riloyd presents</p>
          <h1 className="mt-4 font-black uppercase leading-[0.94]"><span className="block text-2xl sm:text-3xl">Riloyd</span><span className="mt-2 block text-6xl text-primary sm:text-7xl lg:text-8xl">Young</span><span className="mt-1 block text-4xl sm:text-5xl lg:text-6xl">Innovators</span><span className="mt-2 block text-2xl sm:text-3xl">Challenge <span className="text-primary">2026</span></span></h1>
          <p className="mt-5 text-xl font-semibold italic sm:text-2xl">Big Ideas. Brighter Bharat.</p>
          <div className="mt-5 flex flex-wrap gap-5"><div className="flex items-center gap-3"><GraduationCap size={32} className="text-primary"/><p className="text-xs font-bold">For school students<br/>Classes 6–12</p></div><div className="flex items-center gap-3 border-l border-border pl-5"><CalendarDays size={28} className="text-primary"/><p className="text-xs font-bold">2–6 November<br/>2026</p></div></div>
          <p className="mt-5 max-w-[420px] text-sm leading-relaxed text-muted-foreground"><strong className="text-foreground">For school students in Classes 6–12 with a startup or business idea.</strong> Start with a customer problem, imagine a useful solution and share how it could become a business.</p>
          <div className="mt-6 flex flex-wrap gap-3"><Button asChild size="lg"><a href="#registration">Register your idea <ArrowRight size={18}/></a></Button><Button asChild variant="outline"><a href="#idea-video"><Video size={16}/>Your 60-second idea</a></Button></div>
        </div>
      </div>
    </section>
    <div className="young-benefits-band border-b border-border"><div className="mx-auto grid max-w-[1380px] grid-cols-2 gap-5 px-5 py-5 sm:px-6 md:grid-cols-5 lg:px-12">{[[Lightbulb,'Turn ideas into real solutions'],[GraduationCap,'Learn from industry experts'],[Trophy,'Exciting challenge rewards'],[Users,'Mentorship & guidance'],[Rocket,'Young business & startup ideas']].map(([Icon,label])=>{const BenefitIcon=Icon as typeof Lightbulb;return <div key={label as string} className="flex items-center gap-3"><BenefitIcon size={27} className="shrink-0 text-challenge-gold"/><span className="text-xs font-semibold leading-relaxed">{label as string}</span></div>;})}</div></div>
  </>;
}