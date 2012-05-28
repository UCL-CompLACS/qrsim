#include <QRSimTCPClient.h>
#include <iostream>

int main(int argc, char * argv[])
{
  if(argc!=3){
    std::cerr<<"Usage:\n\t"<<std::string(argv[0])<<" ip port"<<std::endl;
    exit(-1);
  }

  GOOGLE_PROTOBUF_VERIFY_VERSION;

  QRSimTCPClient c;
  int numUAVs;
  double timeStep;
  int numErrors = 0;


  c.connectTo(argv[1], atoi(argv[2]));

  std::vector<std::vector<double> > X;
  std::vector<std::vector<double> > eX;

  std::cout << "QRSIM init test";
  bool err = c.init("TaskKeepSpot", X, eX, timeStep, numUAVs, false);

  if (err)
  {
    std::cout << "[PASSED]" << std::endl;
  }
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM reset test ";
  err = c.reset();
  if (err)
    std::cout << "[PASSED]" << std::endl;
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM stepWP test ";
  std::vector<std::vector<double> > WP;
  for (int i = 0; i < numUAVs; i++)
  {
    std::vector<double> wp;

    wp.push_back(0); //wpx
    wp.push_back(0); //wpy
    wp.push_back(-10); //wpz
    wp.push_back(0); //wppsi

    WP.push_back(wp);
  }

  err = c.stepWP(0.1, WP, X, eX);
  if (err)
  {
    std::cout << "[PASSED]" << std::endl;
  }
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM stepCtrl test ";
  std::vector<std::vector<double> > U;
  for (int i = 0; i < numUAVs; i++)
  {
    std::vector<double> u;

    u.push_back(0); //pitch
    u.push_back(0); //roll
    u.push_back(0.53); //throttle
    u.push_back(0); //yaw
    u.push_back(10); //vbat

    U.push_back(u);
  }

  err = c.stepCtrl(0.1, U, X, eX);
  if (err)
  {
    std::cout << "[PASSED]" << std::endl;
  }
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM stepVel test ";
  std::vector<std::vector<double> > V;
  for (int i = 0; i < numUAVs; i++)
  {
    std::vector<double> v;

    v.push_back(0.1); //u
    v.push_back(0); //v
    v.push_back(0); //w

    V.push_back(v);
  }

  err = c.stepVel(0.1, V, X, eX);
  if (err)
  {
    std::cout << "[PASSED]" << std::endl;
  }
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM disconnect test ";
  err = c.disconnect();
  if (err)
  {
    std::cout << "[PASSED]" << std::endl;
  }
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  std::cout << "QRSIM quit test ";
  c.connectTo("127.0.0.1", 10000);
  err = c.quit();
  if (err)
    std::cout << "[PASSED]" << std::endl;
  else
  {
    std::cout << "[FAILED]" << std::endl;
    numErrors++;
  }

  // Optional:  Delete all global objects allocated by libprotobuf.
  google::protobuf::ShutdownProtobufLibrary();

  exit(0);
}
