# VDF Alliance FPGA Contest Round 3 Results

**Congratulations to Ben Devlin for his winning entry with 46 ns/sq latency and Phil Sun for his paper entitled "Modular Exponentiation via Nested Reduction in a Residue Number System"!!**

This repository contains the results and designs submitted for the second VDF FPGA competition. See [FPGA Contest Wiki](https://supranational.atlassian.net/wiki/spaces/VA/pages/36569208/FPGA+Contest) for more information about the contest.

As a reminder, this final round closed at the end of January and focused on the lowest latency design using an alternative representation. It included two tracks, one for the lowest latency FPGA implementation and one for most promising novel research paper. See https://supranational.atlassian.net/wiki/spaces/VA/pages/50102273/Competition+2+Official+Rules+and+Disclosures for more detail. 


## Results

**Paper**

We received two paper submissions, which can be found in the "papers" directory. Thank you to both submitters for their work advancing low latency multiplier designs! Congratulations to Phil Sun, whose paper was selected due to the adaptations of the RNS approach toward low latency along with promising FPGA results. 

**FPGA**

We received 4 submissions from 2 teams for the FPGA portion of the design, both of which used a more traditional Montgomery approach. Great work exploring this approach and seeing how well a less latency focused architecture can perform in this space! 

Designs were evaluated for performance as follows:
  * Run hardware emulation to test basic functionality
  * Synthesis using the provided scripts
  * Run for 2^33 iterations on AWS F1 and check for correctness and performance.

Team Name | Directory | Expected | Actual
----------|-----------|----------|-------
Geriatric Guys with Gates | ggg | 60.2 ns/sq | 60.2 ns/sq
Ben Devlin | devlin0 | 60 ns/sq | 60 ns/sq
Ben Devlin | devlin1 | 49.2 ns/sq | 49.2 ns/sq
Ben Devlin | devlin2 | 46 ns/sq | 46.2 ns/sq
