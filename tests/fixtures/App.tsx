import Deck from './deck/Deck';
import Slide from './deck/Slide';
import Build from './deck/Build';
import Cover from './components/Cover';
import StatGrid from './components/StatGrid';
import CountUp from './components/CountUp';

export default function App() {
  return (
    <Deck>
      <Cover
        nav="Cover"
        kicker="Hermes workflow verification"
        title={<>Interactive decks, <span className="accent-text">verified.</span></>}
        subtitle="A small evidence-safe deck generated to exercise the public Hermes skill."
        foot="Open-source workflow test · no production claims"
        notes="Explain that this is a workflow fixture, not a customer presentation."
      />

      <Slide center nav="Method" notes="Reveal the verification gates one at a time.">
        <h2 className="headline" style={{ marginInline: 'auto' }}>
          Build first. <span className="accent-text">Verify twice.</span>
        </h2>
        <Build at={1}>
          <p className="lead" style={{ marginInline: 'auto' }}>Type-check and compile the application.</p>
        </Build>
        <Build at={2}>
          <p className="lead" style={{ marginInline: 'auto' }}>Inspect rendered slides at wide and narrow viewports.</p>
        </Build>
      </Slide>

      <StatGrid
        nav="Checks"
        kicker="Mechanical gates"
        title="The fixture passed its required checks."
        stats={[
          { value: <CountUp to={1} />, label: 'Typecheck', caption: 'Executed in CI' },
          { value: <CountUp to={1} />, label: 'Production build', caption: 'Executed in CI' },
          { value: <CountUp to={0} />, label: 'Production audit findings', caption: 'npm audit --omit=dev' },
        ]}
        notes="These values describe only this workflow fixture."
      />
    </Deck>
  );
}
