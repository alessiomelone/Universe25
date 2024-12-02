# Universe25 - Social Status & Fights

## Initialization

**Patches**: The environment contains four food dispensers located at the corners of the grid.

**Mice**: An initial population of mice is created with random attributes.

## Mouse attributes

•	**`sex`**: Mice can be male (“M”) or female (“F”).

•	**`energy`**: Represents the health of a mouse. A mouse dies if its energy goes to 0. It is decreased at every tick and in case of fight, the winner has a lower decrease than the loser.

It is necessary for females in order to give birth (they only mate if their energy is higher than 50% of the maximum energy. Can be brought back to `max-energy` when eating.

•	**`age`**: Increases each tick, influences fertility (a mouse is considered fertile in a certain range of age).

•	**`social-status`**: For males, a value between 0 and 1 indicating dominance. Affects the probability of winning fights and a mouse is considered dominant and marked in red if its social-status goes over a certain threshold `dominance-threshold`.

•	`behavior`: Can be “normal” or “beautiful”, affecting movement and interactions. Setting `behavior-change-probability` to 0 allows not to take behavioral change to “beautiful” into account, made for simplicity.

•	**Reproduction**: Females can become pregnant and give birth after a gestation period.

## Model parameters

- `initial-population` of mice. Changing in analysis.
- `max-age` and `death-probability-factor` : after a certain age, the mice start dying with a probability proportional to the exceeding and the death probability factor. Both fixed for simplicity.
- `max-energy` and `energy-loss-rate` are fixed for simplicity and indicate respectively the maximum energy and the energy lost per tick by each mouse.
- `overpopulation-threshold` indicates the number of mice present in a radius of 5 from a certain mouse or patch to be considered overcrowded.
- `pregnancy-duration`, `min-offspring` and `maximum-offspring` for each birth.
- `dominance-threshold` is the threshold after which a mouse in considered dominant by other mice. Changing in analysis.
- `fight-probability-factor` affects the probability of males fighting when overcrowded. Setting it to 1, we force the male mice to fight whenever it’s overcrowded.

## Behavioral dynamics

### Movement

**Seeking Food**: Mice move towards food dispensers when hungry (at meals intervals or if their energy is running below 30% of the total energy).

- **Dominant Males**: Claim a dispenser and hover around it.
- **Non-Dominant Males**: Avoid dispensers near dominant males if possible.
- **Females**: Always go to the nearest dispenser.

**Seeking Mates**: Male mice seek females when ready to mate, every `mating-interval` ticks, set to 0.2 * `max-age`  : a male mouse tries to mate approximately 5 times during its lifespan.

- **Dominant Males**: Avoid mating if a male with a higher social-status is nearby.
- **Non-Dominant Males**: Avoid females near dominant males.

**Random Movement**: Mice move randomly with a bias towards the center when not engaged in other activities.

### Eating

•	Mice eat when they are within a radius of 1 from a food dispenser. They can only eat every `meal-interval` number of ticks, set to 0.1 * `max-age`. This means a mouse eats approximately 10 times during its lifespan.

### Fighting

•	Occurs among male mice when overcrowded.

•	Winning outcomes is based on and affects social status and energy, and can result in death.

### Reproducing

•	Fertile females (fertility based on age) attempt to reproduce based on energy levels and overcrowding.

•	After gestation, they give birth to a random number of offspring.

## Simulation characteristics

The initial configuration allocates the mice randomly on the grid. Because of the moving dynamics implemented, mice move randomly before they have low energy or before their first meal interval.

In that moment, they expectedly tend to cluster around food-dispenser.

Among the features that could be seen in the simulation, one of them is the way dominant non-dominant males and females distributes between the four food-dispenser.

In the early phase of most simulations, the distribution is quite random, until some dominant-males emerge. When that happens, we can see a migration of less-dominant mice to less-populated food-dispenser, while the females tend to stick in the vicinity of their food-dispenser.

This causes some food-dispenser to have a low number of dominant-males while still having a large number of females, while in the food-dispenser with less-dominant males, the ratio females over total mice is lower.

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image.png)

This dynamics causes the food-dispenser where the dominant mice are, to be more prone to mate, increasing the population around a number related to the initial parameters.

## Population peaks and extinction dynamics

The population peaks usually happens in the early phases of the simulation with a large number of mice, while happens randomly before extinction with a lower number of mice.

In the following, we fixed the others parameters to reasonable values to see how initial population affects the peak population.

In fact:

With the following parameters

- `initial-population: 100,` peak population ranging from 380 to 650.

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%201.png)

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%202.png)

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%203.png)

- `initial-population: 10`, ranges 220 to 330.

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%204.png)

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%205.png)

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%206.png)

Even setting the range of offspring per birth from 0 to 10, it is possible to see how over a variable number of ticks and oscillations in the total population values, in all the simulations with these parameters the population eventually goes towards extinction.

Extinction happens to be a degenerate result of one of the negative peaks of the oscillations.

But what leads to extinction? Setting a the `random-seed 12345` we evaluate some different results.

[BF937821-D278-4EC6-A530-14C107D82D31 2.mov](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/BF937821-D278-4EC6-A530-14C107D82D31_2.mov)

Most of the times, as in the video present here it happens when a dominant male dies and leaves a big number of females close to a food dispenser. Among the remaining less-dominant males, sparsely distributed in the other dispensers, none can establish a new position of dominance to create another cluster of dominant mouse and females that could make the population grow again.

Using other dominance-threshold parameters, the situation stays the same, resulting in extinction for the same reason, but in less ticks.

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%207.png)

`maximum-age`: by varying the maximum age, the results are approximately the same, but the times are dilated and the peak is slightly higher, as one would expect.

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%208.png)

Similar result was seen while seen varying `death-probability-factor`.

This suggests that the main reason for extinction is not the aging population, but the number of fights and the establishment of social dominance.

With a higher max-age, we can only see how the total population is oscillating less randomly in a longer timeframe, and it’s possible to see the trend of the overall decreasing peaks.

## Overcrowding threshold

The parameter that affects the most the simulation results is  `overpopulation-threshold`.

It affects the probability of reproducing and is the threshold after which the mice start fighting.

Fixing all the other parameters as before (except for `maximum-offspring`, reduced to 5 for computational reasons) and running the simulation with an over-population-threshold of 40. We obtain the following result:

![image.png](Universe25%20-%20Social%20Status%20&%20Fights%2014fd8d44f8af8086b3b3f406ba507fb3/image%209.png)

Even if the population peak expectedly reaches a significantly higher values than before, the overall trend is the same and mice extinct after 23,000 ticks.
