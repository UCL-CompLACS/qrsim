package qrsimsrvcli;

import java.net.Socket;
import java.net.ServerSocket;
import qrsimsrvcli.QrsSrvCliMsg.*;
import com.google.protobuf.CodedInputStream;
import com.google.protobuf.CodedOutputStream;

class QRSimTCPServer
{
  CodedOutputStream os;
  CodedInputStream is;
  ServerSocket connSocket;
  final int sizeLength;

public QRSimTCPServer(int port) throws Exception
  {
    // work out the length of a Size message,
    // this is constant since Size is a fix32
    sizeLength = Size.newBuilder().setValue(1).build().toByteArray().length;

    // setup a server socket on the desired port
    connSocket = new ServerSocket(port);
  }

public void close() throws Exception
  {
    // close main socket and connected data sockets
    connSocket.close();
  }

public void waitForClient() throws Exception
  {
    // waiting for connection from client    
    connSocket.setSoTimeout(1000);

    // accepting client connection
    Socket dataSocket = connSocket.accept();

    // setting up input and output streams
    is = CodedInputStream.newInstance(dataSocket.getInputStream());
    os = CodedOutputStream.newInstance(dataSocket.getOutputStream());
  }

public Message nextCommand() throws Exception
  {
    // read sizeLength bytes from input
    Size.Builder sb = Size.newBuilder();
    int oldLimit = is.pushLimit(sizeLength);
    do
    {
      sb.mergeFrom(is);
    }while (is.getBytesUntilLimit() > 0);
    is.checkLastTagWas(0);
    is.popLimit(oldLimit); 

    // decode message size
    Size size = sb.build();
    //System.out.println("got size "+size.getValue());

    // read size.getValue() bytes from input
    Message.Builder mb = Message.newBuilder();
    oldLimit = is.pushLimit(size.getValue());
    do
    {
      mb.mergeFrom(is);
    }while (is.getBytesUntilLimit() > 0);
    is.checkLastTagWas(0);
    is.popLimit(oldLimit); 

    // decode message
    Message msg = mb.build();
    //System.out.println("got message of type "+ msg.getType());

    is.resetSizeCounter();
    return msg;
  }

public void sendState(double t, double[][] X,double[][] eX) throws Exception
  {
    // construct a STATE message
    Message.Builder mb = Message.newBuilder();
    mb.setType(Message.Type.STATE);

    State.Builder stb = State.newBuilder();
    stb.setT(t);

    // fill in the values of the state variables
    final int numUAVs = X.length;
    for (int i = 0; i < numUAVs; i++)
    {
      Arrayd.Builder arraydb = Arrayd.newBuilder();
      final int lXi = X[i].length;
      for (int j = 0; j < lXi; j++)
      {
        arraydb.addValue(X[i][j]);
      }
      stb.addX(arraydb);
    }

    for (int i = 0; i < numUAVs; i++)
    {
      Arrayd.Builder arraydb = Arrayd.newBuilder();
      final int leXi = eX[i].length;
      for (int j = 0; j < leXi; j++)
      {
        arraydb.addValue(eX[i][j]);
      }
      stb.addEX(arraydb);
    }

    mb.setState(stb);

    // send the message
    send(mb);
  }

public void sendAck(boolean error) throws Exception
  {
    // send ack without message
    sendAck(error, null);
  }

public void sendAck(boolean error, String emsg) throws Exception
  {
    // build ACK message
    Message.Builder mb = Message.newBuilder();
    mb.setType(Message.Type.ACK);

    Ack.Builder ab = Ack.newBuilder();
    ab.setError(error);
    if(emsg!=null){
      ab.setMsg(emsg);
    }
    
    mb.setAck(ab);    

    // send the message off
    send(mb);
  }

public void sendTaskInfo(double timeStep,int numUAVs) throws Exception
  {
    // build TASKINFO message
    Message.Builder mb = Message.newBuilder();
    mb.setType(Message.Type.TASKINFO);

    TaskInfo.Builder tb = TaskInfo.newBuilder();
    tb.setTimestep(timeStep);
    tb.setNumUAVs(numUAVs);
    
    mb.setTaskInfo(tb);    

    // send the message off
    send(mb);
  }

private void send(Message.Builder mb)throws Exception
  {
  
  // build message
  Message msg = mb.build();
  
  final int msgSize = msg.getSerializedSize();
  
  // build size
  Size size = Size.newBuilder().setValue(msgSize).build();

  // send size
  size.writeTo(os);
  // send msg
  msg.writeTo(os);

  os.flush();
}

// helper to parse the cmd fiels of STEP messages into Matlab arrays
public static double[][] parseStepCmd(Step step)
{
  double[][] cmd = new double[step.getCmdCount()][step.getCmd(0).getValueCount()];
  
  for(int i=0; i<step.getCmdCount(); i++){
    Arrayd ad = step.getCmd(i);  
    for(int j=0; j<ad.getValueCount(); j++){
      cmd[i][j] = ad.getValue(j);
    }
  }
  return cmd;
}

// helper to parse State messages into Matlab arrays of State
public static double[][] parseSetState(SetState setState)
{
  double[][] X = new double[setState.getXCount()][setState.getX(0).getValueCount()];
  
  for(int i=0; i<setState.getXCount(); i++){
    Arrayd ad = setState.getX(i);  
    for(int j=0; j<ad.getValueCount(); j++){
      X[i][j] = ad.getValue(j);
    }
  }
  return X;
}

}