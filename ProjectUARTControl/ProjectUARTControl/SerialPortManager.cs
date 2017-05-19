using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO.Ports;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing;
using System.Runtime.CompilerServices;

namespace ProjectUARTControl
{
    public class SerialPortManager
    {
        private enum COMMAND { STOP, AIR_COND, HEAT };

        private const int BAUD_RATE = 9600;
        private const int DATA_BITS = 8;
        private const int PARITY_BITS = 0;
        private const int STOP_BITS = 1;

        private RichTextBox displayWindow;
        private Label lblSystemStatus;
        private SerialPort serialPort;

        private int wantedTemp = 25;
        private COMMAND currentCommand;

        public SerialPortManager(RichTextBox rtb, Label lbl)
        {
            serialPort = new SerialPort();
            displayWindow = rtb;
            lblSystemStatus = lbl;

            lblSystemStatus.Text = "";
        }

        public IList<string> GetAvailablePorts()
        {
            IList<string> ports = new List<string>();
            foreach (string str in SerialPort.GetPortNames())
            {
                ports.Add(str);
            }
            return ports;
        }

        public bool Connected()
        {
            return serialPort.IsOpen;
        }

        public bool OpenConnection(string comPortName)
        {
            try
            {
                if (serialPort.IsOpen) serialPort.Close();
 
                serialPort.PortName = comPortName;
                serialPort.BaudRate = BAUD_RATE;
                serialPort.DataBits = DATA_BITS;
                serialPort.Parity = PARITY_BITS;
                serialPort.StopBits = (StopBits)STOP_BITS;

                serialPort.DataReceived += new SerialDataReceivedEventHandler(TemperatureDataReceivedHandler);

                serialPort.Open();

                DisplayData("Port opened at " + DateTime.Now + "\n");
                return true;
            }
            catch (Exception ex)
            {
                DisplayData(ex.Message + "\n");
                return false;
            }
        }

        [MethodImpl(MethodImplOptions.Synchronized)]
        public void CloseConnection()
        {
            if (serialPort.IsOpen) serialPort.Close();
            serialPort.DataReceived -= new SerialDataReceivedEventHandler(TemperatureDataReceivedHandler);
            DisplayData("Port closed at " + DateTime.Now + "\n");
        }

        public void SendData(byte data)
        {
            wantedTemp = data;
        }

        [MethodImpl(MethodImplOptions.Synchronized)]
        private void Send(byte data)
        {
            byte[] writeData = new byte[1];
            writeData[0] = data;
            serialPort.Write(writeData, 0, 1);

            string command = "";
            switch (data)
            {
                case 0:
                    command = "Stop system";
                    break;
                case 1:
                    command = "Start Air conditioner";
                    break;
                case 2:
                    command = "Start heating";
                    break;
            }

            DisplayData("[SEND] " + DateTime.Now + " -- " + command + "\n");
        }

        [MethodImpl(MethodImplOptions.Synchronized)]
        private void DisplayData(string msg)
        {
            displayWindow.Invoke(new EventHandler(delegate
            {
                displayWindow.SelectedText = string.Empty;
                displayWindow.SelectionFont = new Font(displayWindow.SelectionFont, FontStyle.Bold);
                displayWindow.AppendText(msg);
                displayWindow.ScrollToCaret();
            }));
        }

        [MethodImpl(MethodImplOptions.Synchronized)]
        private void TemperatureDataReceivedHandler(object sender, SerialDataReceivedEventArgs e)
        {
            if (sender != null)
            {
                SerialPort sp = (SerialPort)sender;
                
                // read two bytes of data and convert it to grade Celsius!
                while (sp.BytesToRead < 2) { /*do nothing*/}
                
                byte[] buffer = new byte[2];
                sp.Read(buffer, 0, 2);
                string hex = BitConverter.ToString(buffer);
                hex = hex.Replace("-", "");
                int value = Convert.ToInt32(hex, 16);
                double cels = value/8.0f * 0.0625f;

                DisplayData("[RECEIVE] " + DateTime.Now + " -- " + Math.Round(cels, 2) + "\n");

                // compare the current temp with the wanted temperature and 
                // if command modification is needed send a new signal
                if (wantedTemp > cels + 0.5 && currentCommand != COMMAND.HEAT)
                {
                    Send(2);
                    currentCommand = COMMAND.HEAT;
                    lblSystemStatus.Text = "Heating";
                }
                if (wantedTemp < cels - 0.5 && currentCommand != COMMAND.AIR_COND)
                {
                    Send(1);
                    currentCommand = COMMAND.AIR_COND;
                    lblSystemStatus.Text = "Cooling";
                }
                if (wantedTemp >= cels - 0.5 && wantedTemp <= cels + 0.5 && currentCommand != COMMAND.STOP)
                {
                    Send(0);
                    currentCommand = COMMAND.STOP;
                    lblSystemStatus.Text = "Stopped";
                }

            }
            else
            {
                DisplayData("[RECEIVE] Error: could not receive data!");
            }
        }

    }
}
