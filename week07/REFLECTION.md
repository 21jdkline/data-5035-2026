# Reflection — Programming Paradigms

## Which programming paradigm did you use where?
I used two paradigms. Imperative Python handled data generation in notebook 01
and pilot selection in notebook 03. Declarative SQL handled the scoring pipeline in notebook 02.

## Why did you choose each paradigm in that area?
Data generation had to be imperative because each segment's values depend on its location
along the corridor. The urban factor drives range, EV share, crash rates, and straightness
— all of which are calculated in sequence from position. There is no way to declare that
logic as an output shape.

Pilot selection is also imperative. Whether a segment gets selected depends on what was
already selected before it. I iterated through candidates in score order, checked each one
against all previously selected sites for distance and corridor, and added it only if it
passes both checks. SQL can rank rows but cannot carry state from one row's decision into the next.

SQL was the right fit for scoring because all 103 segments are processed identically.
I used CTEs to break the scoring into logical layers, one per dimension, which makes each
piece independently readable and testable. This structure also maps directly to how I would
build a silver-layer transformation in our Databricks environment at work.

## What additional data would improve your confidence?
VMT-normalized crash rates would improve safety scoring. Crashes per lane-mile penalizes
high-traffic segments that may actually be safer per trip. Monthly EV traffic counts would
help because annual averages mask the winter demand peaks when anxiety about range is highest.

## What political or operational risks exist?
On I-70 in Missouri, the freight industry has a strong presence. A technology that reduces
range issues for electric trucks could face opposition framed as enabling driver displacement,
even if the pilot only targets passenger vehicles. Along stretches where local leaders are
politically resistant to EV infrastructure, local officials could frame the pilot as forced
adoption regardless of how it is positioned.

Operationally, the 30 mph charging lane creates a 40 mph speed differential with adjacent
traffic. That is one of the most dangerous conditions in highway design.