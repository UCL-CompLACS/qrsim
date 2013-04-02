QRSim
=====

Examples of quadrotor helicopters models described in the literature (e.g. [ [1] ](#one), [ [2] ](#two),[ [3] ](#three)) tend to focus on reproducing only the dynamic aspects the aerial platform and their
primary use is in the domain of closed loop flight control. 

When the aim is simulating more general higher level tasks that involve multiple platforms which sense and react in their environment, the usefulness of such models is limited.
This document describes the multi-vehicle simulator software QRSim developed to
devise and test algorithm that allow a set of UAVs to communicate and cooperate to
achieve common goals. In addition to realistically simulate the dynamic of the aerial platform (learned from flight tests), the software simulates the sensors suite that typically equips a UAV (i.e. GPS, IMU, camera) and the endogenous and exogenous sources of inaccuracies that characterize them. Environmental effects that act directly (e.g. wind) or indirectly (e.g. the plume dispersion) the task are also part of the simulation.

To offer a well structured and challenging set of control and machine learning problems
the simulator includes the implementation of a number of non trivial task scenarios.

## Videos
[![ScreenShot1](https://github.com/UCL-CompLACS/qrsim/doc/Youtube_Video1.png)](http://youtu.be/5ka4tP0z2RQ)
[![ScreenShot2](https://github.com/UCL-CompLACS/qrsim/doc/Youtube_Video2.png)](http://youtu.be/SjOaX4Z0iLk)

## Documentation
* Installation and use manual <a href="https://github.com/UCL-CompLACS/qrsim/doc/manual.pdf">[pdf]<a/>
* Scenarios manual <a href="https://github.com/UCL-CompLACS/qrsim/doc/scenarios.pdf">[pdf]<a/>
* Learning exercise sheet <a href="https://github.com/UCL-CompLACS/qrsim/doc/exercises.pdf">[pdf]<a/> 


## Citation
If you <a href="https://github.com/UCL-CompLACS/qrsim/doc/qrsimcite.bib">[bib]<a/>

## License

## Support

### References
1.<a id="one"></a>  S. Bouabdallah. _Design and control of quadrotors with application to autonomous flying._ PhD thesis, EPFL, 2007

2.<a id="two"></a>  C. Balas. _Modelling and linear control of a quadrotor._ Master's thesis, School of
Engineering, Cranfield University, 2007.

3.<a id="three"></a>  P. Pounds, R. Mahony, and P. Corke. _Modelling and control of a quad-rotor robot._
In ACRA, 2006.




