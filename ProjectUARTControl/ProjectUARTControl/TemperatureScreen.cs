using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace ProjectUARTControl
{
    public partial class TemperatureScreen : Form
    {
        private SerialPortManager manager;

        public TemperatureScreen()
        {
            InitializeComponent();
            lblNote.Text = "Note: UART properties ----- Baud Rate = 9600; Data Bits = 8; Parity Bits = 0; Stop Bits = 1";


            manager = new SerialPortManager(txtReadValues, lblSystem);
            updateComponents();
            txtSend.Text = "25";
        }

        /**
         * Refresh the list of available ports and display them in the combo box.
         */
        private void btnRefresh_Click(object sender, EventArgs e)
        {
            comboPorts.ResetText();
            comboPorts.DataSource = manager.GetAvailablePorts();
            updateComponents();
        }

        /**
         * The connect button has dual role:
         * when the program is not connected to a device, tries to connect to the selected COM port
         * when the program is connected to a device, the it will disconnect from it.
         */ 
        private void btnConnect_Click(object sender, EventArgs e)
        {
            if (manager.Connected())
            {
                manager.CloseConnection();
            }
            else
            {
                manager.OpenConnection(comboPorts.SelectedItem.ToString());
            }
            updateComponents();
        }

        /**
         * The send button sends the information from the text view to the connected device.
         * It is disabled when there is connected device.
         */ 
        private void btnSend_Click(object sender, EventArgs e)
        {
            try
            {
                manager.SendData(Convert.ToByte(txtSend.Text));
            }
            catch (Exception)
            {
                MessageBox.Show("Invalid input", "Warning", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
        }

        /**
         * Update the Connect button and the Status label accordingly
         * When there are no available ports the Connect button should be disabled.
         * Similarly, when the program is not connected to a device it should not be
         * allowed to send any information, so the send button is disabled.
         */ 
        private void updateComponents()
        {
            if (comboPorts.Items.Count < 1)
            {
                btnConnect.Enabled = false;
            }
            else
            {
                btnConnect.Enabled = true;
            }

            if (manager.Connected())
            {
                lblStatusValue.Text = "Connected";
                btnConnect.Text = "Disconnect";
                btnSend.Enabled = true;
            }
            else
            {
                lblStatusValue.Text = "Disconnected";
                btnConnect.Text = "Connect";
                btnSend.Enabled = false;
            }
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            txtReadValues.Clear();
        }

        private void label1_Click(object sender, EventArgs e)
        {

        }
    }
}
