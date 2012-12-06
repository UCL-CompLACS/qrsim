#include <QRSimTCPClient.h>
#include <iostream>
#include <cmath>
#include <unistd.h>

/// constructor
QRSimTCPClient::QRSimTCPClient()
{
  // init the size object to an arbitrary value in order to
  // save its byte size (note that this works because size is
  // of type fixed32 so its length does not depend on its value)

  size.set_value(1);
  sizeSize = size.ByteSize();
  initialized = false;
  socketOpen = false;
}

/// destructor
QRSimTCPClient::~QRSimTCPClient()
{
  if (socketOpen)
  {
    close(sockfd);
  }
}

/// Connects to the server at the specified IP and PORT
bool QRSimTCPClient::connectTo(std::string ip, int port)
{
  // set up the connection socket give the destination address and port
  sockfd = socket(AF_INET, SOCK_STREAM, 0);

  if (sockfd < 0)
  {
    std::cerr << "error opening socket" << std::endl;
    return false;
  }
  else
  {
    socketOpen = true;
  }

  struct timeval timeout;
  timeout.tv_sec = 20;
  timeout.tv_usec = 0;

  if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout, sizeof(timeout)) < 0)
  {
    std::cerr << "setting setsockopt failed" << std::endl;
    return false;
  }

  bzero(&servaddr, sizeof(servaddr));
  servaddr.sin_family = AF_INET;

  if (inet_aton(ip.c_str(), &servaddr.sin_addr) == 0)
  {
    std::cerr << "address " << ip << " not valid!" << std::endl;
  }

  servaddr.sin_port = htons(port);

  // attempt connecting to server
  connect(sockfd, (struct sockaddr *)&servaddr, sizeof(servaddr));

  if (sockfd < 0)
  {
    std::cerr << "socket error" << std::endl;
    return false;
  }
  else
  {
    return true;
  }
}

/// Sends to the server the command to initialize the simulator
bool QRSimTCPClient::init(std::string task, std::vector<std::vector<double> > & X,
                          std::vector<std::vector<double> > & eX, double& tStep, int& nUAVs, bool realTime = false)
{
  // fill in the INIT message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::INIT);
  msg.mutable_init()->set_task(task);
  msg.mutable_init()->set_realtime(realTime);

  // send it off to the server
  bool sent = send();

  // wait for confirmation message containing the simulator state
  bool confirmedS = receiveState(X, eX);

  // wait for message containing the task infos
  bool confirmedI = receiveInfo(tStep, nUAVs);

  numUAVs = nUAVs;
  timeStep = tStep;

  if (sent && confirmedS && confirmedI)
  {
    initialized = true;
  }
  // report how things went
  return sent && confirmedS && confirmedI;
}

/// Sends a reset command to the server,
bool QRSimTCPClient::reset()
{
  if (!initialized)
  {
    std::cerr << "before anything else qrsim you must init the simulator" << std::endl;
    return false;
  }

  // fill in the RESET message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::RESET);
  msg.mutable_reset()->set_value(true);

  // send it off to the server
  bool sent = send();

  // wait for confirmation message
  bool confirmed = receiveAck();

  // report how things went
  return sent && confirmed;
}

/// Disconnects from the server
bool QRSimTCPClient::disconnect()
{
  if (!initialized)
  {
    std::cerr << "before anything else qrsim you must init the simulator" << std::endl;
    return false;
  }

  // fill in the DISCONNECT message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::DISCONNECT);
  // specify that the simulator should stay alive
  msg.mutable_disconnect()->set_quit(false);

  // send message off to the server
  bool sent = send();

  // wait for confirmation message
  bool confirmed = receiveAck();

  // report how things went
  return sent && confirmed;
}

/// Turns off the simulator
bool QRSimTCPClient::quit()
{
  if (!initialized)
  {
    std::cerr << "before anything else qrsim you must init the simulator" << std::endl;
    return false;
  }

  // fill in the DISCONNECT message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::DISCONNECT);
  // specify that the simulator should quit
  msg.mutable_disconnect()->set_quit(true);

  // send message off to the server
  bool sent = send();

  // wait for confirmation message
  bool confirmed = receiveAck();

  // report how things went
  return sent && confirmed;
}

/// Sets the UAVs noiseless states
bool QRSimTCPClient::setState(const std::vector<std::vector<double> > & X)
{
  if (!initialized)
  {
    std::cerr << "before anything else qrsim you must init the simulator" << std::endl;
    return false;
  }

  // fill in the SETSTATE message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::SETSTATE);

  if (numUAVs != X.size())
  {
    std::cerr << "the number of state vectors is " << X.size() << " instead of being equal to the number of UAVs "
        << numUAVs << std::endl;
    return false;
  }

  // fill in the message with the UAVs states
  for (int i = 0; i < X.size(); i++)
  {
    if ((X[i].size() != 3) && (X[i].size() != 6) && (X[i].size() != 12) && (X[i].size() != 13))
    {
      std::cerr << "wrong size of state vector " << X[i].size() << " instead of 3 or 6 or 12 or 13" << std::endl;
      return false;
    }
    qrsimsrvcli::Arrayd* xi = msg.mutable_setsstate()->add_x();
    for (int j = 0; j < X[i].size(); j++)
    {
      xi->add_value(X[i][j]);
    }
  }

  // send message off to the server
  bool sent = send();

  // wait for confirmation message
  bool confirmed = receiveAck();

  // report how things went
  return sent && confirmed;
}

/// Steps forward the simulator given some waypoints
bool QRSimTCPClient::stepWP(double dt, const std::vector<std::vector<double> > & WP,
                            std::vector<std::vector<double> > & X, std::vector<std::vector<double> > & eX)
{
  if (numUAVs != WP.size())
  {
    std::cerr << "the number of waypoint vectors is " << WP.size() << " instead of being equal to the number of UAVs "
        << numUAVs << std::endl;
    return false;
  }

  for(int i=0; i<numUAVs; i++){
  if (WP[i].size() != 4)
  {
    std::cerr << "wrong size of WP vector " << WP[i].size() << " instead of 4" << std::endl;
    return false;
  }
  }

  return step(qrsimsrvcli::Step::WP,dt,WP,X,eX);
}

/// Steps forward the simulator given some control inputs
bool QRSimTCPClient::stepCtrl(double dt, const std::vector<std::vector<double> > & ctrl,
                              std::vector<std::vector<double> > & X, std::vector<std::vector<double> > & eX)
{
  if (numUAVs != ctrl.size())
  {
    std::cerr << "the number of control vectors is " << ctrl.size() << " instead of being equal to the number of UAVs "
        << numUAVs << std::endl;
    return false;
  }

  for(int i=0; i<numUAVs; i++){
  if (ctrl[i].size() != 5)
  {
    std::cerr << "wrong size of control vector " << ctrl[i].size() << " instead of 5" << std::endl;
    return false;
  }
  }
  return step(qrsimsrvcli::Step::CTRL,dt,ctrl,X,eX);
}

/// Steps forward the simulator given some control inputs
bool QRSimTCPClient::stepVel(double dt, const std::vector<std::vector<double> > & vel,
                              std::vector<std::vector<double> > & X, std::vector<std::vector<double> > & eX)
{
  if (numUAVs != vel.size())
  {
    std::cerr << "the number of vel vectors is " << vel.size() << " instead of being equal to the number of UAVs "
        << numUAVs << std::endl;
    return false;
  }

  for(int i=0; i<numUAVs; i++){
  if (vel[i].size() != 3)
  {
    std::cerr << "wrong size of vel vector " << vel[i].size() << " instead of 3" << std::endl;
    return false;
  }
  }
  return step(qrsimsrvcli::Step::VEL,dt,vel,X,eX);
}

/// Steps forward the simulator given some control inputs
bool QRSimTCPClient::step(qrsimsrvcli::Step::Type type, double dt, const std::vector<std::vector<double> > & cmd,
                              std::vector<std::vector<double> > & X, std::vector<std::vector<double> > & eX)
{
  if (!initialized)
  {
    std::cerr << "before anything else qrsim you must init the simulator" << std::endl;
    return false;
  }

  double tmp;
  double f = modf(dt / timeStep, &tmp);

  //std::cout<<"dt:"<<dt<<" timestep:"<<timeStep<<" f:"<<f<<" 1-f:"<<(fabs(1-f))<<" tol:"<<TOL<<std::endl;

  if (!((f < TOL) || (fabs(1 - f) < TOL)))
  {
    std::cerr << "the time increment " << dt << " must be a multiple of the timestep " << timeStep << std::endl;
    return false;
  }

  // fill in the STEP message
  msg.Clear();
  msg.set_type(qrsimsrvcli::Message::STEP);
  msg.mutable_step()->set_dt(dt);
  msg.mutable_step()->set_type(type);

  // fill in the message with the controls
  for (int i = 0; i < cmd.size(); i++)
  {
    qrsimsrvcli::Arrayd* ui = msg.mutable_step()->add_cmd();
    for (int j = 0; j < cmd[i].size(); j++)
    {
      ui->add_value(cmd[i][j]);
    }
  }

  // send message off to the server
  bool sent = send();

  // wait for confirmation message
  bool confirmed = receiveState(X, eX);

  // report how things went
  return sent && confirmed;
}

/// Sends the content of the current msg message
bool QRSimTCPClient::send()
{
  int n;
  int msgSize = msg.ByteSize();
  size.set_value(msgSize);

  // serialize and send the size of the message
  size.SerializeToArray(buf, size.ByteSize());
  n = sendto(sockfd, buf, sizeSize, 0, (struct sockaddr *)&servaddr, sizeof(servaddr));
  if (n != sizeSize)
  {
    std::cerr << "send length error, written " << n << " bytes instead of " << sizeSize << std::endl;
    return false;
  }

  // serialize and send the message
  msg.SerializeToArray(buf, msgSize);
  n = sendto(sockfd, buf, msgSize, 0, (struct sockaddr *)&servaddr, sizeof(servaddr));
  if (n != msgSize)
  {
    std::cerr << "send msg error, written " << n << " bytes instead of " << msgSize << std::endl;
    return false;
  }

  return true;
}

/// Waits for confirmation of reception from server
bool QRSimTCPClient::receiveAck()
{
  int n;

  // receive and parse the size of the message
  n = recv(sockfd, buf, sizeSize, 0);
  if (n != sizeSize)
  {
    return false;
  }
  size.ParseFromArray(buf, sizeSize);

  // receive and parse the message
  n = recv(sockfd, buf, size.value(), 0);
  if (n != size.value())
  {
    return false;
  }
  msg.ParseFromArray(buf, size.value());

  // check if it is an error
  if (msg.type() == qrsimsrvcli::Message::ACK)
  {
    if (msg.ack().error())
    {
      std::cerr << "error: " << msg.ack().msg() << std::endl;
      return false;
    }
    else
    {
      return true;
    }
  }

  return false;
}

/// Waits for task info from server
bool QRSimTCPClient::receiveInfo(double& dt, int& numUAVs)
{
  int n;

  // receive and parse the size of the message
  n = recv(sockfd, buf, sizeSize, 0);
  if (n != sizeSize)
  {
    return false;
  }
  size.ParseFromArray(buf, sizeSize);

  // receive and parse the message
  n = recv(sockfd, buf, size.value(), 0);
  if (n != size.value())
  {
    return false;
  }
  msg.ParseFromArray(buf, size.value());

  // check the received message
  if (msg.type() == qrsimsrvcli::Message::TASKINFO)
  {
    dt = msg.taskinfo().timestep();
    numUAVs = msg.taskinfo().numuavs();

    return true;
  }

  // error message, report it
  if ((msg.type() == qrsimsrvcli::Message::ACK) && msg.ack().error())
  {
    std::cerr << "error: " << msg.ack().msg() << std::endl;
  }
  else
  {
    std::cerr << "unexpected reply message" << std::endl;
  }

  return false;
}

/// Waits for new UAVs state from server
bool QRSimTCPClient::receiveState(std::vector<std::vector<double> > & X, std::vector<std::vector<double> > & eX)
{
  int n;

  // receive and parse the size of the message
  n = recv(sockfd, buf, sizeSize, 0);
  if (n != sizeSize)
  {
    return false;
  }
  size.ParseFromArray(buf, sizeSize);

  // receive and parse the message
  n = recv(sockfd, buf, size.value(), 0);
  if (n != size.value())
  {
    return false;
  }
  msg.ParseFromArray(buf, size.value());

  // check the received message
  if (msg.type() == qrsimsrvcli::Message::STATE)
  {
    int numUAVs = msg.state().x_size();
    if (X.size() != numUAVs)
      X.resize(numUAVs);
    if (eX.size() != numUAVs)
      eX.resize(numUAVs);

    // parse the noiseless state
    for (int i = 0; i < msg.state().x_size(); i++)
    {
      const qrsimsrvcli::Arrayd& Xi = msg.state().x(i);
      int lenght = Xi.value_size();
      if (X[i].size() != lenght)
        X[i].resize(lenght);
      for (int j = 0; j < lenght; j++)
      {
        X[i][j] = Xi.value(j);
      }
    }

    // parse the noisy state
    for (int i = 0; i < msg.state().ex_size(); i++)
    {
      const qrsimsrvcli::Arrayd& eXi = msg.state().ex(i);
      int lenght = eXi.value_size();
      if (eX[i].size() != lenght)
        eX[i].resize(lenght);
      for (int j = 0; j < lenght; j++)
      {
        eX[i][j] = eXi.value(j);
      }
    }
    return true;
  }

  // error message, report it
  if ((msg.type() == qrsimsrvcli::Message::ACK) && msg.ack().error())
  {
    std::cerr << "error: " << msg.ack().msg() << std::endl;
  }
  else
  {
    std::cerr << "unexpected reply message" << std::endl;
  }

  return false;
}
