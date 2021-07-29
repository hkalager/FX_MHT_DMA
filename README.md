# FX_MHT_DMA
This code is prepared for the article titled "Trading the foreign exchange market with technical analysis and Bayesian Statistics" published in the Journal of Empirical Finance.

You can access the article at https://doi.org/10.1016/j.jempfin.2021.07.006

Please cite the article as "Hassanniakalager, A, Sermpinis, G & Stasinakis, C 2021, 'Trading the Foreign Exchange Market with Technical Analysis and Bayesian Statistics', Journal of Empirical Finance."

Running the codes:

The main procedure is called "Step1_MainRunner.m". You can amend/add parameters and/or hyperparameters based on your needs. All callable functions are uploaded as well.

Warning:

- Running these codes can take up to 1 hour per asset(e.g. EUR/USD) per study period (e.g. out of sample year 2015).
- These codes use a random seed to generate the results. Despite all efforts to stabilise the processes, getting the same results as in the paper is not guaranteed. 

Dataset:

The data for currency exchange rates are from an anonymous FX brokerage in csv format like "EURUSD.csv". Each csv file containts date, time(00:00), open, high, low, closing prices and trading volumes. You may collect the same data from Bloomberg Terminal, Thomson Reuters, or any market data source. 

Third-party scripts:

I) The scripts performing the Romano, Wolf, and Sheikh (2008)'s k-FWE test is from Michael Wolf's repository with the University of Zurich at https://www.econ.uzh.ch/en/people/faculty/wolf/publications.html#Programming_Code All contents under the folder "kfwe" is from this source;

II) The scripts performing the Relevance Vector Machine (RVM) of Tipping (2001) is from Mike Tipping's repository at http://www.miketipping.com/downloads.htm. All contents under the folder "RVM2" is from this source; 

III) The majority of the codes for bootstrapping and model confidence set of Hansen et al (2011) from Kevin Sheppard's MATLAB repository at https://www.kevinsheppard.com/code/matlab/mfe-toolbox/ All scripts in the folder "bootstrap" are from Kevin Sheppard along with the scripts "bsds.m" and "stationary_bootstrap.m"; 

IV) The scripts performing the Dynamic Model Averaging of Koop and Korobilis (2012) is from Dimitris Korobilis' repository at https://sites.google.com/site/dimitriskorobilis/matlab/dma. Most contents under the folder "DMA" is from this source. The DMA function has been adapted to match my coding style;

All third-party codes are provided as a mirror to the original repositories. 

Further information:

All scripts provided here are as is. Subject to change at all time.
