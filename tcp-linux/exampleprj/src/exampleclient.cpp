#include <QRSimTCPClient.h>
#include <iostream>
#include <string.h>

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

  // connect to the simulator
  bool err = c.init("TaskKeepSpot", X, eX, timeStep, numUAVs, true);

  std::vector<std::vector<double> > WP;

  // create a waypoint for the helicopter
  for (int i = 0; i < numUAVs; i++)
  {
    std::vector<double> wp;

    wp.push_back(0); //wpx
    wp.push_back(0); //wpy
    wp.push_back(-10); //wpz
    wp.push_back(0); //wppsi

    WP.push_back(wp);
  }


  err = c.stepWP(10, WP, X, eX);
  if (err)
  {
    std::cout << "final state" << std::endl;
    for (int i = 0; i < numUAVs; i++)
    {
      std::cout << "UAV" << i << "   X:";
      for (int j = 0; j < 13; j++)
        std::cout << X[i][j] << ",";

      std::cout << " eX:";
      for (int j = 0; j < 20; j++)
        std::cout << eX[i][j] << ",";
    }
    std::cout << std::endl;
  }
  else
  {
    std::cout << "not able to get final state" << std::endl;
  }

  err = c.quit();
  if (err)
    std::cout << "quitting..." << std::endl;
  else
  {
    std::cout << "not able to quit!" << std::endl;
  }

  // Optional:  Delete all global objects allocated by libprotobuf.
  google::protobuf::ShutdownProtobufLibrary();

  exit(0);
}
