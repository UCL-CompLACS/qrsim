#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string>
#include <vector>
#include <qrs_srv_cli_msg.pb.h>

class QRSimTCPClient
{
  int sockfd;
  struct sockaddr_in servaddr;
  qrsimsrvcli::Message msg;
  qrsimsrvcli::Size size;
  int sizeSize;
  char buf[10000];
  int numUAVs;
  double timeStep;
  const static double TOL = 1e-6; // tolerance used to compare times
  bool initialized;
  bool socketOpen;

private:
  /// \brief Sends the content of the current msg message
  ///
  /// Sends the content of the current message held in the
  /// class variable msg using the currently open socket.
  /// Assumes that msg is already correctly filled in.
  /// Prepends the length of the message.
  /// \return true if the expected number of bytes was sent
  ///
  bool send();

  /// \brief Waits for confirmation of reception from server
  ///
  /// Blocking method that wait for confirmation of reception
  /// from the server
  /// \return true command executed, false error condition
  ///
  bool receiveAck();

  /// \brief Waits for new UAVs state from server
  ///
  /// Blocking method that wait for the server to send the state
  /// of all the UAVs; this is a reply to a step command.
  /// \return X set of new UAVs states
  ///        13:[x,y,z,phi,theta,psi,u,v,w,p,q,r,thrust]
  ///           px,py,pz         [m]     position (NED coordinates)
  ///           phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///           u,v,w            [m/s]   velocity in body coordinates
  ///           p,q,r            [rad/s] rotational velocity  in body coordinates
  ///           thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
  /// \return true step executed correctly, false otherwise
  ///
  bool receiveState(std::vector< std::vector< double > > & X, std::vector< std::vector< double > > & eX);

  /// \brief Waits for task info from server
  ///
  /// Blocking method that waits for the task parameters
  /// from the server
  /// \return dt timestep used by the simulator
  /// \return numUAVs number of uavs in the task
  /// \return true info data received, false error condition
  ///
  bool receiveInfo(double& dt, int& numUAVs);

  /// \brief Steps forward the simulator given some command inputs
  ///
  /// Step forward the simulator giving to each of the UAVs the specified
  /// control commands as input; this command will fail if the number control vectors
  /// does not match the number of UAVs or if the dimension of a control vector is not 4
  /// \param type the type of control inputs, waypoints, velocities or controls
  /// \param dt amount of time [s] the simulator is stepped forward of
  /// \param cmd commans inputs, one array for each UAV
  /// \return X noiseles UAVs state output, one array for each UAV
  ///        13: [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
  ///            px,py,pz         [m]     position (NED coordinates)
  ///            phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///            u,v,w            [m/s]   velocity in body coordinates
  ///            p,q,r            [rad/s] rotational velocity  in body coordinates
  ///            thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
  /// \return true if the simulator advanced in time as expected
  ///
  bool step(qrsimsrvcli::Step::Type type, double dt, const std::vector< std::vector < double > > & cmd,
      std::vector< std::vector< double > > & X, std::vector< std::vector< double > > & eX);

public:

  /// \brief Connects to the server at the specified IP and PORT
  ///
  /// Connects to the Matlab server of QRSim listening at the
  /// IP and PORT specified
  /// \param ip
  /// \param port
  /// \return true if connected to the server false otherwise
  ///
  bool connectTo(std::string ip, int port);

  /// \brief Sends to the server the command to initialize the simulator:
  ///
  /// Send to the server the command to initialize the simulator and to load
  /// the configuration specified in the task file
  /// \param task filename of the task that qrsim will load at init
  /// \return X noiseles UAVs state output, one array for each UAV
  ///        13: [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
  ///            px,py,pz         [m]     position (NED coordinates)
  ///            phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///            u,v,w            [m/s]   velocity in body coordinates
  ///            p,q,r            [rad/s] rotational velocity  in body coordinates
  ///            thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
  /// \return dt timestep used by the simulator
  /// \return numUAVs number of uavs in the task
  /// \param realTime if true the simulator will run no faster than real-time,
  ///        as fast as possible otherwise
  /// \return true if the simulator initialised correctly
  ///
  bool init(std::string task, std::vector< std::vector< double > > & X,
            std::vector< std::vector< double > > & eX, double& tStep,
            int& nUAVs, bool realTime);

  /// \brief  Sends a reset command to the server,
  ///
  /// Sends a reset command to the server, this will cause the simulator
  /// to set itself to the initial state defined in the task.
  /// \return true if the simulator reset
  ///
  bool reset();

  /// \brief Disconnects from the server
  ///
  /// Disconnect from the server without turning off the simulator.
  /// \return true if the client is now disconnected
  ///
  bool disconnect();

  /// \brief Turns off the simulator
  ///
  /// Sends to the server a command to turn off the simulator,
  /// this will obviously also produce a disconnect
  /// \return true if simulator agreed to quit
  ///
  bool quit();

  /// \brief Sets the UAVs noiseless states
  ///
  /// Send to the server the command to set the UAV states to the
  /// values provided; this command will fail if the number of state vectors
  /// does not match the number of UAVs or if the state values are
  /// not within limits
  /// \return X UAVs noiseless states, generally this is a vector with
  ///        of N vector of size 3, 6, 12 or 13 (where N is the number of UAVs)
  ///        3: [x,y,z]
  ///        6: [x,y,z,phi,theta,psi]
  ///        12:[x,y,z,phi,theta,psi,u,v,w,p,q,r]
  ///        13:[x,y,z,phi,theta,psi,u,v,w,p,q,r,thrust]
  ///           px,py,pz         [m]     position (NED coordinates)
  ///           phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///           u,v,w            [m/s]   velocity in body coordinates
  ///           p,q,r            [rad/s] rotational velocity  in body coordinates
  ///           thrust           [N]     rotors thrust
  /// \return true if simulator set the state
  ///
  bool setState(const std::vector< std::vector< double > > & X);

  /// \brief Steps forward the simulator given some waypoints
  ///
  /// Step forward the simulator giving to each of the UAVs the specified
  /// waypoint as input; this command will fail if the number of waypoints
  /// does not match the number of UAVs or if the dimension of a waypoint is not 4
  /// \param dt amount of time [s] the simulator is stepped forward of
  /// \param WP waypoints inputs, one 4 dimensional array for each UAV
  ///        4: [wx,wy,wz,wpsi]
  ///           wx,wy,wz         [m]     position of the waypoint (NED coordinates)
  ///           wpsi             [rad]   UAV heading at the waypoint
  /// \return X noiseles UAVs state output, one array for each UAV
  ///        13: [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
  ///            px,py,pz         [m]     position (NED coordinates)
  ///            phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///            u,v,w            [m/s]   velocity in body coordinates
  ///            p,q,r            [rad/s] rotational velocity  in body coordinates
  ///            thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
  /// \return true if the simulator advanced in time as expected
  ///
  bool stepWP(double dt, const std::vector< std::vector < double > > & WP,
      std::vector< std::vector< double > > & X, std::vector< std::vector< double > > & eX);

  /// \brief Steps forward the simulator given some control inputs
  ///
  /// Step forward the simulator giving to each of the UAVs the specified
  /// control commands as input; this command will fail if the number control vectors
  /// does not match the number of UAVs or if the dimension of a control vector is not 4
  /// \param dt amount of time [s] the simulator is stepped forward of
  /// \param ctrl control inputs, one 5 dimensional array for each UAV
  ///        5: [pt,rl,th,ya,bat]
  ///           pt  [-0.89..0.89]  [rad]   commanded pitch
  ///           rl  [-0.89..0.89]  [rad]   commanded roll
  ///           th  [0..1]         unitless commanded throttle
  ///           ya  [-4.4,4.4]     [rad/s] commanded yaw velocity
  ///           bat [9..12]        [Volts] battery voltage
  /// \return X noiseles UAVs state output, one array for each UAV
  ///        13: [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
  ///            px,py,pz         [m]     position (NED coordinates)
  ///            phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///            u,v,w            [m/s]   velocity in body coordinates
  ///            p,q,r            [rad/s] rotational velocity  in body coordinates
  ///            thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)
  /// \return true if the simulator advanced in time as expected
  ///
  bool stepCtrl(double dt, const std::vector< std::vector < double > > & ctrl,
      std::vector< std::vector< double > > & X, std::vector< std::vector< double > > & eX);

  /// \brief Steps forward the simulator given some control inputs
  ///
  /// Step forward the simulator giving to each of the UAVs the specified
  /// control commands as input; this command will fail if the number control vectors
  /// does not match the number of UAVs or if the dimension of a control vector is not 4
  /// \param dt amount of time [s] the simulator is stepped forward of
  /// \param vel velocity inputs, one 3 dimension array for each UAV
  ///        3: [u,v,w]
  ///            u,v,w            [m/s]   commanded velocity in body coordinates
  /// \return X noiseles UAVs state output, one array for each UAV
  ///        13: [px;py;pz;phi;theta;psi;u;v;w;p;q;r;thrust]
  ///            px,py,pz         [m]     position (NED coordinates)
  ///            phi,theta,psi    [rad]   attitude in Euler angles right-hand ZYX convention
  ///            u,v,w            [m/s]   velocity in body coordinates
  ///            p,q,r            [rad/s] rotational velocity  in body coordinates
  ///            thrust           [N]     rotors thrust
  /// \return eX noisy UAVs state output, one array for each UAV
  ///        19: [~px;~py;~pz;~phi;~theta;~psi;0;0;0;~p;~q;~r;0;~ax;~ay;~az; ~h;~pxdot;~pydot;~hdot]
  ///            ~px,~py,~pz      [m]     position estimated by GPS (NED coordinates)
  ///            ~phi,~theta,~psi [rad]   estimated attitude in Euler angles right-hand ZYX convention
  ///            0,0,0                    placeholder (the uav does not provide velocity estimation)
  ///            ~p,~q,~r         [rad/s] measured rotational velocity in body coordinates
  ///            0                        placeholder (the uav does not provide thrust estimation)
  ///            ~ax,~ay,~az      [m/s^2] measured acceleration in body coordinates
  ///            ~h               [m]     estimated altitude from altimeter NED, POSITIVE UP!
  ///            ~pxdot           [m/s]   x velocity from GPS (NED coordinates)
  ///             ~pydot           [m/s]   y velocity from GPS (NED coordinates)
  ///            ~hdot            [m/s]   altitude rate from altimeter (NED coordinates)  ///
  /// \return true if the simulator advanced in time as expected
  ///
  bool stepVel(double dt, const std::vector<std::vector<double> > & vel,
      std::vector< std::vector< double > > & X, std::vector< std::vector< double > > & eX);

  /// \brief constructor
  ///
  /// constructor
  QRSimTCPClient();

  /// \brief Virtual deconstructor
  ///
  /// Virtual deconstructor
  virtual ~QRSimTCPClient();

};
