#######################################################################################################################
# File:             Add-on.ScriptSigning.psm1                                                                         #
# Author:           Kirk Munro                                                                                        #
# Publisher:        Quest Software, Inc.                                                                              #
# Copyright:        © 2010 Quest Software, Inc.. All rights reserved.                                                 #
# Usage:            To load this module in your Script Editor:                                                        #
#                   1. Open the Script Editor.                                                                        #
#                   2. Select "PowerShell Libraries" from the File menu.                                              #
#                   3. Check the Add-on.ScriptSigning module.                                                         #
#                   4. Click on OK to close the "PowerShell Libraries" dialog.                                        #
#                   Alternatively you can load the module from the embedded console by invoking this:                 #
#                       Import-Module -Name Add-on.ScriptSigning                                                      #
#                   Please provide feedback on the PowerGUI Forums.                                                   #
#######################################################################################################################

Set-StrictMode -Version 2

#region Initialize the Script Editor Add-on.

if ($Host.Name –ne 'PowerGUIScriptEditorHost') { return }
if ($Host.Version -lt '2.1.1.1202') {
	[System.Windows.Forms.MessageBox]::Show("The ""$(Split-Path -Path $PSScriptRoot -Leaf)"" Add-on module requires version 2.1.0.1200 or later of the Script Editor. The current Script Editor version is $($Host.Version).$([System.Environment]::NewLine * 2)Please upgrade to version 2.1.0.1200 and try again.","Version 2.1.0.1200 or later is required",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
	return
}

$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

#endregion

#region Load resources from disk.

$iconLibrary = @{
	SignSettingsIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SignSettings.ico",16,16
	SignSettingsIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SignSettings.ico",32,32
	  SignScriptIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SignScript.ico",16,16
	  SignScriptIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\SignScript.ico",32,32
	CertificatesIcon16 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Certificates.ico",16,16
	CertificatesIcon32 = New-Object System.Drawing.Icon -ArgumentList "$PSScriptRoot\Resources\Certificates.ico",32,32
}

$imageLibrary = @{
	SignSettingsImage16 = $iconLibrary['SignSettingsIcon16'].ToBitmap()
	SignSettingsImage32 = $iconLibrary['SignSettingsIcon32'].ToBitmap()
	  SignScriptImage16 = $iconLibrary['SignScriptIcon16'].ToBitmap()
	CertificatesImage16 = $iconLibrary['CertificatesIcon16'].ToBitmap()
}

#endregion

#region Define the Win32ViewCertificate class

if (-not ('PowerShellTypeExtensions.Win32ViewCertificate' -as [System.Type])) {
	$cSharpCode = @'
using System;
using System.Runtime.InteropServices;

namespace PowerShellTypeExtensions {

	public class Win32ViewCertificate
	{
		public const int CRYPTUI_DISABLE_ADDTOSTORE = 0x00000010;

		[DllImport("CryptUI.dll", CharSet = CharSet.Auto, SetLastError = true)]
		public static extern Boolean CryptUIDlgViewCertificate(
			ref CRYPTUI_VIEWCERTIFICATE_STRUCT pCertViewInfo,
			ref bool pfPropertiesChanged
		);

		public struct CRYPTUI_VIEWCERTIFICATE_STRUCT
		{
			public int dwSize;
			public IntPtr hwndParent;
			public int dwFlags;
			[MarshalAs(UnmanagedType.LPWStr)]
			public String szTitle;
			public IntPtr pCertContext;
			public IntPtr rgszPurposes;
			public int cPurposes;
			public IntPtr pCryptProviderData; // or hWVTStateData
			public Boolean fpCryptProviderDataTrustedUsage;
			public int idxSigner;
			public int idxCert;
			public Boolean fCounterSigner;
			public int idxCounterSigner;
			public int cStores;
			public IntPtr rghStores;
			public int cPropSheetPages;
			public IntPtr rgPropSheetPages;
			public int nStartPage;
		}

		public static void Show(System.Security.Cryptography.X509Certificates.X509Certificate2 cert) {
			CRYPTUI_VIEWCERTIFICATE_STRUCT certViewInfo = new CRYPTUI_VIEWCERTIFICATE_STRUCT();
			certViewInfo.dwSize = Marshal.SizeOf(certViewInfo);
			certViewInfo.pCertContext = cert.Handle;
			certViewInfo.szTitle = "Certificate";
			certViewInfo.dwFlags = CRYPTUI_DISABLE_ADDTOSTORE;
			certViewInfo.nStartPage = 0;
			bool fPropertiesChanged = false;
			if (!CryptUIDlgViewCertificate(ref certViewInfo, ref fPropertiesChanged))
			{
				int error = Marshal.GetLastWin32Error();
				if (error != 1223)
				{
					//System.Windows.Forms.MessageBox.Show(error.ToString());
				}
			}
		}
	}
}
'@

	Add-Type -ReferencedAssemblies System.Windows.Forms -TypeDefinition $cSharpCode
}

#endregion

#region Define the Script Signing Options dialog.

$scriptSigningOptionsDialogCode = @'
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

namespace Addon
{
	namespace ScriptSigning
	{
		public partial class ScriptSigningOptionsForm : Form
		{
			public const int CRYPTUI_DISABLE_ADDTOSTORE = 0x00000010;

			[DllImport("CryptUI.dll", CharSet = CharSet.Auto, SetLastError = true)]
			public static extern Boolean CryptUIDlgViewCertificate(
				ref CRYPTUI_VIEWCERTIFICATE_STRUCT pCertViewInfo,
				ref bool pfPropertiesChanged
			);

			public struct CRYPTUI_VIEWCERTIFICATE_STRUCT
			{
				public int dwSize;
				public IntPtr hwndParent;
				public int dwFlags;
				[MarshalAs(UnmanagedType.LPWStr)]
				public String szTitle;
				public IntPtr pCertContext;
				public IntPtr rgszPurposes;
				public int cPurposes;
				public IntPtr pCryptProviderData; // or hWVTStateData
				public Boolean fpCryptProviderDataTrustedUsage;
				public int idxSigner;
				public int idxCert;
				public Boolean fCounterSigner;
				public int idxCounterSigner;
				public int cStores;
				public IntPtr rghStores;
				public int cPropSheetPages;
				public IntPtr rgPropSheetPages;
				public int nStartPage;
			}

			public ScriptSigningOptionsForm()
			{
				InitializeComponent();
			}

			private void listViewCertificates_ItemSelectionChanged(object sender, ListViewItemSelectionChangedEventArgs e)
			{
				this.buttonSetAsDefault.Enabled = (this.listViewCertificates.SelectedItems.Count > 0);
				this.buttonViewCertificate.Enabled = (this.listViewCertificates.SelectedItems.Count > 0);
			}

			private void buttonSetAsDefault_Click(object sender, EventArgs e)
			{
				if (this.listViewCertificates.SelectedIndices.Count > 0)
				{
					for (System.Int32 index = 0; index < listViewCertificates.Items.Count; index++)
					{
						if (index == listViewCertificates.SelectedIndices[0])
						{
							_DefaultCertificate = index;
							listViewCertificates.Items[index].Font = new System.Drawing.Font(listViewCertificates.Items[index].Font, System.Drawing.FontStyle.Bold);
						}
						else if (listViewCertificates.Items[index].Font.Bold)
						{
							listViewCertificates.Items[index].Font = new System.Drawing.Font(listViewCertificates.Items[index].Font, System.Drawing.FontStyle.Regular);
						}
					}
				}
			}

			private void buttonViewCertificate_Click(object sender, EventArgs e)
			{
				if (this.listViewCertificates.SelectedIndices.Count > 0)
				{
					CRYPTUI_VIEWCERTIFICATE_STRUCT certViewInfo = new CRYPTUI_VIEWCERTIFICATE_STRUCT();
					certViewInfo.dwSize = Marshal.SizeOf(certViewInfo);
					certViewInfo.pCertContext = _ScriptSigningCertificates[listViewCertificates.SelectedIndices[0]].Handle;
					certViewInfo.szTitle = "Certificate";
					certViewInfo.dwFlags = CRYPTUI_DISABLE_ADDTOSTORE;
					certViewInfo.nStartPage = 0;
					bool fPropertiesChanged = false;
					if (!CryptUIDlgViewCertificate(ref certViewInfo, ref fPropertiesChanged))
					{
						int error = Marshal.GetLastWin32Error();
						if (error != 1223)
						{
							//System.Windows.Forms.MessageBox.Show(error.ToString());
						}
					}
				}
			}

			private void checkBoxTimestampServer_CheckedChanged(object sender, EventArgs e)
			{
				this.textBoxTimestampServer.Enabled = this.checkBoxTimestampServer.Checked;
				this.textBoxTimestampServer.ReadOnly = !this.checkBoxTimestampServer.Checked;
			}

			public System.Drawing.Image Image
			{
				set
				{
					this.pictureBoxIcon.Image = value;
				}
			}

			private System.Int32 _DefaultCertificate = -1;
			public System.Int32 DefaultCertificate
			{
				get
				{
					return _DefaultCertificate;
				}
			}

			private System.Security.Cryptography.X509Certificates.X509Certificate2[] _ScriptSigningCertificates;

			public void LoadCertificates(System.Security.Cryptography.X509Certificates.X509Certificate2[] ScriptSigningCertificates, System.Int32 DefaultCertificate)
			{
				_ScriptSigningCertificates = ScriptSigningCertificates;
				this.listViewCertificates.Items.Clear();
				System.Int32 count = ScriptSigningCertificates.Length;
				if (count > 0)
				{
					System.Security.Cryptography.Oid commonNameId = new System.Security.Cryptography.Oid("2.5.4.3");
					System.Security.Cryptography.Oid organizationId = new System.Security.Cryptography.Oid("2.5.4.10");

					for (System.Int32 index = 0; index < count; index++)
					{
						ListViewItem newItem = new ListViewItem();
						string subjectDisplayName = ScriptSigningCertificates[index].Subject;
						string issuerDisplayName = ScriptSigningCertificates[index].Issuer;

						System.Security.Cryptography.AsnEncodedData encodedCommonName = new System.Security.Cryptography.AsnEncodedData(commonNameId, ScriptSigningCertificates[index].SubjectName.RawData);
						string formattedCommonName = encodedCommonName.Format(false);
						if (subjectDisplayName.Contains(formattedCommonName))
						{
							subjectDisplayName = formattedCommonName;
						}
						else
						{
							System.Security.Cryptography.AsnEncodedData encodedOrganization = new System.Security.Cryptography.AsnEncodedData(organizationId, ScriptSigningCertificates[index].SubjectName.RawData);
							string formattedOrganization = encodedOrganization.Format(false);
							if (subjectDisplayName.Contains(formattedOrganization))
							{
								subjectDisplayName = formattedOrganization;
							}
						}

						encodedCommonName = new System.Security.Cryptography.AsnEncodedData(commonNameId, ScriptSigningCertificates[index].IssuerName.RawData);
						formattedCommonName = encodedCommonName.Format(false);
						if (issuerDisplayName.Contains(formattedCommonName))
						{
							issuerDisplayName = formattedCommonName;
						}
						else
						{
							System.Security.Cryptography.AsnEncodedData encodedOrganization = new System.Security.Cryptography.AsnEncodedData(organizationId, ScriptSigningCertificates[index].IssuerName.RawData);
							string formattedOrganization = encodedOrganization.Format(false);
							if (issuerDisplayName.Contains(formattedOrganization))
							{
								issuerDisplayName = formattedOrganization;
							}
						}

						newItem.Text = subjectDisplayName;
						newItem.SubItems.Add(issuerDisplayName);
						newItem.SubItems.Add(ScriptSigningCertificates[index].NotAfter.ToString());
						newItem.SubItems.Add(ScriptSigningCertificates[index].SerialNumber);
						newItem.SubItems.Add(ScriptSigningCertificates[index].Thumbprint);
						newItem.UseItemStyleForSubItems = true;
						if (index == DefaultCertificate)
						{
							_DefaultCertificate = DefaultCertificate;
							newItem.Font = new System.Drawing.Font(newItem.Font, System.Drawing.FontStyle.Bold);
						}
						this.listViewCertificates.Items.Add(newItem);
					}
				}
			}

			public IncludeChain IncludeChain
			{
				get
				{
					if (this.radioButtonAll.Checked)
					{
						return IncludeChain.All;
					}
					else if (this.radioButtonSigner.Checked)
					{
						return IncludeChain.Signer;
					}
					else
					{
						return IncludeChain.NotRoot;
					}
				}
				set
				{
					switch (value)
					{
						case IncludeChain.All:
							this.radioButtonAll.Checked = true;
							break;
						case IncludeChain.NotRoot:
							this.radioButtonNotRoot.Checked = true;
							break;
						case IncludeChain.Signer:
							this.radioButtonSigner.Checked = true;
							break;
					}
				}
			}

			public System.Boolean AutoSave
			{
				get
				{
					return this.radioButtonAutoSave.Checked;
				}
				set
				{
					if (value)
					{
						this.radioButtonAutoSave.Checked = true;
					}
					else
					{
						this.radioButtonPromptToSave.Checked = true;
					}
				}
			}

			public System.String TimestampServer
			{
				get
				{
					if (this.checkBoxTimestampServer.Checked)
					{
						return this.textBoxTimestampServer.Text.Trim();
					}
					else
					{
						return null;
					}
				}
				set
				{
					if (value.Trim().Length > 0)
					{
						this.checkBoxTimestampServer.Checked = true;
						this.textBoxTimestampServer.Text = value.Trim();
					}
					else
					{
						this.checkBoxTimestampServer.Checked = false;
						this.textBoxTimestampServer.Text = null;
					}
					this.textBoxTimestampServer.Enabled = this.checkBoxTimestampServer.Checked;
					this.textBoxTimestampServer.ReadOnly = !this.checkBoxTimestampServer.Checked;
				}
			}
		}

		partial class ScriptSigningOptionsForm
		{
			/// <summary>
			/// Required designer variable.
			/// </summary>
			private System.ComponentModel.IContainer components = null;

			/// <summary>
			/// Clean up any resources being used.
			/// </summary>
			/// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
			protected override void Dispose(bool disposing)
			{
				if (disposing && (components != null))
				{
					components.Dispose();
				}
				base.Dispose(disposing);
			}

			#region Windows Form Designer generated code

			/// <summary>
			/// Required method for Designer support - do not modify
			/// the contents of this method with the code editor.
			/// </summary>
			private void InitializeComponent()
			{
				System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(ScriptSigningOptionsForm));
				this.buttonCancel = new System.Windows.Forms.Button();
				this.buttonOK = new System.Windows.Forms.Button();
				this.pictureBoxIcon = new System.Windows.Forms.PictureBox();
				this.labelCertificate = new System.Windows.Forms.Label();
				this.labelInstructions = new System.Windows.Forms.Label();
				this.textBoxTimestampServer = new System.Windows.Forms.TextBox();
				this.listViewCertificates = new System.Windows.Forms.ListView();
				this.columnHeaderSubject = new System.Windows.Forms.ColumnHeader();
				this.columnHeaderIssuer = new System.Windows.Forms.ColumnHeader();
				this.columnHeaderNotAfter = new System.Windows.Forms.ColumnHeader();
				this.columnHeaderSerialNumber = new System.Windows.Forms.ColumnHeader();
				this.columnHeaderThumbprint = new System.Windows.Forms.ColumnHeader();
				this.groupBoxIncludeOptions = new System.Windows.Forms.GroupBox();
				this.radioButtonAll = new System.Windows.Forms.RadioButton();
				this.radioButtonSigner = new System.Windows.Forms.RadioButton();
				this.radioButtonNotRoot = new System.Windows.Forms.RadioButton();
				this.checkBoxTimestampServer = new System.Windows.Forms.CheckBox();
				this.buttonSetAsDefault = new System.Windows.Forms.Button();
				this.buttonViewCertificate = new System.Windows.Forms.Button();
				this.groupBoxAutoSave = new System.Windows.Forms.GroupBox();
				this.radioButtonPromptToSave = new System.Windows.Forms.RadioButton();
				this.radioButtonAutoSave = new System.Windows.Forms.RadioButton();
				((System.ComponentModel.ISupportInitialize)(this.pictureBoxIcon)).BeginInit();
				this.groupBoxIncludeOptions.SuspendLayout();
				this.groupBoxAutoSave.SuspendLayout();
				this.SuspendLayout();
				// 
				// buttonCancel
				// 
				this.buttonCancel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
				this.buttonCancel.DialogResult = System.Windows.Forms.DialogResult.Cancel;
				this.buttonCancel.Location = new System.Drawing.Point(471, 490);
				this.buttonCancel.Name = "buttonCancel";
				this.buttonCancel.Size = new System.Drawing.Size(75, 23);
				this.buttonCancel.TabIndex = 15;
				this.buttonCancel.Text = "Cancel";
				this.buttonCancel.UseVisualStyleBackColor = true;
				// 
				// buttonOK
				// 
				this.buttonOK.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
				this.buttonOK.DialogResult = System.Windows.Forms.DialogResult.OK;
				this.buttonOK.Location = new System.Drawing.Point(390, 490);
				this.buttonOK.Name = "buttonOK";
				this.buttonOK.Size = new System.Drawing.Size(75, 23);
				this.buttonOK.TabIndex = 14;
				this.buttonOK.Text = "OK";
				this.buttonOK.UseVisualStyleBackColor = true;
				// 
				// pictureBoxIcon
				// 
				this.pictureBoxIcon.InitialImage = null;
				this.pictureBoxIcon.Location = new System.Drawing.Point(23, 23);
				this.pictureBoxIcon.Name = "pictureBoxIcon";
				this.pictureBoxIcon.Size = new System.Drawing.Size(32, 32);
				this.pictureBoxIcon.SizeMode = System.Windows.Forms.PictureBoxSizeMode.AutoSize;
				this.pictureBoxIcon.TabIndex = 25;
				this.pictureBoxIcon.TabStop = false;
				// 
				// labelCertificate
				// 
				this.labelCertificate.AutoSize = true;
				this.labelCertificate.Location = new System.Drawing.Point(13, 80);
				this.labelCertificate.Name = "labelCertificate";
				this.labelCertificate.Size = new System.Drawing.Size(130, 13);
				this.labelCertificate.TabIndex = 1;
				this.labelCertificate.Text = "&Script Signing &Certificates:";
				// 
				// labelInstructions
				// 
				this.labelInstructions.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.labelInstructions.Location = new System.Drawing.Point(73, 19);
				this.labelInstructions.Name = "labelInstructions";
				this.labelInstructions.Size = new System.Drawing.Size(473, 40);
				this.labelInstructions.TabIndex = 0;
				this.labelInstructions.Text = "Use the fields provided below to configure how script and module files will be signed in the Script Editor. The script signing certificate in bold is the one that will be used to sign your script and module files.";
				// 
				// textBoxTimestampServer
				// 
				this.textBoxTimestampServer.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.textBoxTimestampServer.Enabled = false;
				this.textBoxTimestampServer.Location = new System.Drawing.Point(132, 451);
				this.textBoxTimestampServer.Name = "textBoxTimestampServer";
				this.textBoxTimestampServer.ReadOnly = true;
				this.textBoxTimestampServer.Size = new System.Drawing.Size(414, 20);
				this.textBoxTimestampServer.TabIndex = 13;
				// 
				// listViewCertificates
				// 
				this.listViewCertificates.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.listViewCertificates.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.columnHeaderSubject,
            this.columnHeaderIssuer,
            this.columnHeaderNotAfter,
            this.columnHeaderSerialNumber,
            this.columnHeaderThumbprint});
				this.listViewCertificates.FullRowSelect = true;
				this.listViewCertificates.HeaderStyle = System.Windows.Forms.ColumnHeaderStyle.Nonclickable;
				this.listViewCertificates.Location = new System.Drawing.Point(16, 96);
				this.listViewCertificates.MultiSelect = false;
				this.listViewCertificates.Name = "listViewCertificates";
				this.listViewCertificates.Size = new System.Drawing.Size(530, 101);
				this.listViewCertificates.TabIndex = 2;
				this.listViewCertificates.UseCompatibleStateImageBehavior = false;
				this.listViewCertificates.View = System.Windows.Forms.View.Details;
				this.listViewCertificates.ItemSelectionChanged += new System.Windows.Forms.ListViewItemSelectionChangedEventHandler(this.listViewCertificates_ItemSelectionChanged);
				// 
				// columnHeaderSubject
				// 
				this.columnHeaderSubject.Text = "Issued To";
				this.columnHeaderSubject.Width = 170;
				// 
				// columnHeaderIssuer
				// 
				this.columnHeaderIssuer.Text = "Issued By";
				this.columnHeaderIssuer.Width = 170;
				// 
				// columnHeaderNotAfter
				// 
				this.columnHeaderNotAfter.Text = "Expiration Date";
				this.columnHeaderNotAfter.Width = 170;
				// 
				// columnHeaderSerialNumber
				// 
				this.columnHeaderSerialNumber.Text = "Serial Number";
				this.columnHeaderSerialNumber.Width = 230;
				// 
				// columnHeaderThumbprint
				// 
				this.columnHeaderThumbprint.Text = "Thumbprint";
				this.columnHeaderThumbprint.Width = 330;
				// 
				// groupBoxIncludeOptions
				// 
				this.groupBoxIncludeOptions.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.groupBoxIncludeOptions.Controls.Add(this.radioButtonAll);
				this.groupBoxIncludeOptions.Controls.Add(this.radioButtonSigner);
				this.groupBoxIncludeOptions.Controls.Add(this.radioButtonNotRoot);
				this.groupBoxIncludeOptions.Location = new System.Drawing.Point(16, 331);
				this.groupBoxIncludeOptions.Name = "groupBoxIncludeOptions";
				this.groupBoxIncludeOptions.Size = new System.Drawing.Size(530, 100);
				this.groupBoxIncludeOptions.TabIndex = 8;
				this.groupBoxIncludeOptions.TabStop = false;
				this.groupBoxIncludeOptions.Text = "Include Options";
				// 
				// radioButtonAll
				// 
				this.radioButtonAll.AutoSize = true;
				this.radioButtonAll.Checked = true;
				this.radioButtonAll.Location = new System.Drawing.Point(13, 23);
				this.radioButtonAll.Name = "radioButtonAll";
				this.radioButtonAll.Size = new System.Drawing.Size(257, 17);
				this.radioButtonAll.TabIndex = 9;
				this.radioButtonAll.Text = "Includes &all the certificates in the certificate chain (default)";
				this.radioButtonAll.UseVisualStyleBackColor = true;
				// 
				// radioButtonSigner
				// 
				this.radioButtonSigner.AutoSize = true;
				this.radioButtonSigner.Location = new System.Drawing.Point(13, 46);
				this.radioButtonSigner.Name = "radioButtonSigner";
				this.radioButtonSigner.Size = new System.Drawing.Size(192, 17);
				this.radioButtonSigner.TabIndex = 10;
				this.radioButtonSigner.Text = "Includes only the si&gner\'s certificate";
				this.radioButtonSigner.UseVisualStyleBackColor = true;
				// 
				// radioButtonNotRoot
				// 
				this.radioButtonNotRoot.AutoSize = true;
				this.radioButtonNotRoot.Location = new System.Drawing.Point(13, 69);
				this.radioButtonNotRoot.Name = "radioButtonNotRoot";
				this.radioButtonNotRoot.Size = new System.Drawing.Size(445, 17);
				this.radioButtonNotRoot.TabIndex = 11;
				this.radioButtonNotRoot.TabStop = true;
				this.radioButtonNotRoot.Text = "Includes all of the certificates in the certificate chain, except for the &root a" +
					"uthority";
				this.radioButtonNotRoot.UseVisualStyleBackColor = true;
				// 
				// checkBoxTimestampServer
				// 
				this.checkBoxTimestampServer.AutoSize = true;
				this.checkBoxTimestampServer.Location = new System.Drawing.Point(16, 452);
				this.checkBoxTimestampServer.Name = "checkBoxTimestampServer";
				this.checkBoxTimestampServer.Size = new System.Drawing.Size(114, 17);
				this.checkBoxTimestampServer.TabIndex = 12;
				this.checkBoxTimestampServer.Text = "&Timestamp Server:";
				this.checkBoxTimestampServer.UseVisualStyleBackColor = true;
				this.checkBoxTimestampServer.CheckedChanged += new System.EventHandler(this.checkBoxTimestampServer_CheckedChanged);
				// 
				// buttonSetAsDefault
				// 
				this.buttonSetAsDefault.Enabled = false;
				this.buttonSetAsDefault.Location = new System.Drawing.Point(16, 203);
				this.buttonSetAsDefault.Name = "buttonSetAsDefault";
				this.buttonSetAsDefault.Size = new System.Drawing.Size(216, 23);
				this.buttonSetAsDefault.TabIndex = 3;
				this.buttonSetAsDefault.Text = "Set as &Default Script Signing Certificate";
				this.buttonSetAsDefault.UseVisualStyleBackColor = true;
				this.buttonSetAsDefault.Click += new System.EventHandler(this.buttonSetAsDefault_Click);
				// 
				// buttonViewCertificate
				// 
				this.buttonViewCertificate.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
				this.buttonViewCertificate.Enabled = false;
				this.buttonViewCertificate.Location = new System.Drawing.Point(447, 203);
				this.buttonViewCertificate.Name = "buttonViewCertificate";
				this.buttonViewCertificate.Size = new System.Drawing.Size(100, 23);
				this.buttonViewCertificate.TabIndex = 4;
				this.buttonViewCertificate.Text = "&View Certificate";
				this.buttonViewCertificate.UseVisualStyleBackColor = true;
				this.buttonViewCertificate.Click += new System.EventHandler(this.buttonViewCertificate_Click);
				// 
				// groupBoxAutoSave
				// 
				this.groupBoxAutoSave.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left)
							| System.Windows.Forms.AnchorStyles.Right)));
				this.groupBoxAutoSave.Controls.Add(this.radioButtonPromptToSave);
				this.groupBoxAutoSave.Controls.Add(this.radioButtonAutoSave);
				this.groupBoxAutoSave.Location = new System.Drawing.Point(16, 240);
				this.groupBoxAutoSave.Name = "groupBoxAutoSave";
				this.groupBoxAutoSave.Size = new System.Drawing.Size(530, 78);
				this.groupBoxAutoSave.TabIndex = 5;
				this.groupBoxAutoSave.TabStop = false;
				this.groupBoxAutoSave.Text = "Auto-Save Options";
				// 
				// radioButtonPromptToSave
				// 
				this.radioButtonPromptToSave.AutoSize = true;
				this.radioButtonPromptToSave.Checked = true;
				this.radioButtonPromptToSave.Location = new System.Drawing.Point(13, 46);
				this.radioButtonPromptToSave.Name = "radioButtonPromptToSave";
				this.radioButtonPromptToSave.Size = new System.Drawing.Size(212, 17);
				this.radioButtonPromptToSave.TabIndex = 7;
				this.radioButtonPromptToSave.TabStop = true;
				this.radioButtonPromptToSave.Text = "&Prompt to save files before signing them";
				this.radioButtonPromptToSave.UseVisualStyleBackColor = true;
				// 
				// radioButtonAutoSave
				// 
				this.radioButtonAutoSave.AutoSize = true;
				this.radioButtonAutoSave.Location = new System.Drawing.Point(13, 23);
				this.radioButtonAutoSave.Name = "radioButtonAutoSave";
				this.radioButtonAutoSave.Size = new System.Drawing.Size(238, 17);
				this.radioButtonAutoSave.TabIndex = 6;
				this.radioButtonAutoSave.Text = "Automatically &save files when they are signed";
				this.radioButtonAutoSave.UseVisualStyleBackColor = true;
				// 
				// ScriptSigningOptionsForm
				// 
				this.AcceptButton = this.buttonOK;
				this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
				this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
				this.CancelButton = this.buttonCancel;
				this.ClientSize = new System.Drawing.Size(558, 525);
				this.ControlBox = false;
				this.Controls.Add(this.groupBoxAutoSave);
				this.Controls.Add(this.buttonSetAsDefault);
				this.Controls.Add(this.buttonViewCertificate);
				this.Controls.Add(this.checkBoxTimestampServer);
				this.Controls.Add(this.groupBoxIncludeOptions);
				this.Controls.Add(this.listViewCertificates);
				this.Controls.Add(this.buttonCancel);
				this.Controls.Add(this.buttonOK);
				this.Controls.Add(this.pictureBoxIcon);
				this.Controls.Add(this.labelCertificate);
				this.Controls.Add(this.labelInstructions);
				this.Controls.Add(this.textBoxTimestampServer);
				this.MaximizeBox = false;
				this.MinimizeBox = false;
				this.Name = "ScriptSigningOptionsForm";
				this.ShowIcon = false;
				this.ShowInTaskbar = false;
				this.SizeGripStyle = System.Windows.Forms.SizeGripStyle.Hide;
				this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
				this.Text = "Script Signing Options";
				((System.ComponentModel.ISupportInitialize)(this.pictureBoxIcon)).EndInit();
				this.groupBoxIncludeOptions.ResumeLayout(false);
				this.groupBoxIncludeOptions.PerformLayout();
				this.groupBoxAutoSave.ResumeLayout(false);
				this.groupBoxAutoSave.PerformLayout();
				this.ResumeLayout(false);
				this.PerformLayout();

			}

			#endregion

			private System.Windows.Forms.Button buttonCancel;
			private System.Windows.Forms.Button buttonOK;
			private System.Windows.Forms.PictureBox pictureBoxIcon;
			private System.Windows.Forms.Label labelCertificate;
			private System.Windows.Forms.Label labelInstructions;
			private System.Windows.Forms.TextBox textBoxTimestampServer;
			private System.Windows.Forms.ListView listViewCertificates;
			private System.Windows.Forms.GroupBox groupBoxIncludeOptions;
			private System.Windows.Forms.RadioButton radioButtonAll;
			private System.Windows.Forms.RadioButton radioButtonSigner;
			private System.Windows.Forms.RadioButton radioButtonNotRoot;
			private System.Windows.Forms.ColumnHeader columnHeaderSubject;
			private System.Windows.Forms.ColumnHeader columnHeaderIssuer;
			private System.Windows.Forms.ColumnHeader columnHeaderNotAfter;
			private System.Windows.Forms.ColumnHeader columnHeaderSerialNumber;
			private System.Windows.Forms.ColumnHeader columnHeaderThumbprint;
			private System.Windows.Forms.CheckBox checkBoxTimestampServer;
			private System.Windows.Forms.Button buttonSetAsDefault;
			private System.Windows.Forms.Button buttonViewCertificate;
			private System.Windows.Forms.GroupBox groupBoxAutoSave;
			private System.Windows.Forms.RadioButton radioButtonPromptToSave;
			private System.Windows.Forms.RadioButton radioButtonAutoSave;
		}

		public enum IncludeChain : int
		{
			All = 0,
			NotRoot = 1,
			Signer = 2
		}
	}
}
'@
if (-not ('Addon.ScriptSigning.ScriptSigningOptionsForm' -as [System.Type])) {
	Add-Type -ReferencedAssemblies 'System.Windows.Forms','System.Drawing' -TypeDefinition $scriptSigningOptionsDialogCode
}

#endregion

#region Define internal helper functions.

Export-ModuleMember

function Get-ScriptSigningCertificate {
	foreach ($certificateStoreLocation in Get-ChildItem -LiteralPath Certificate:: -ErrorAction SilentlyContinue) {
		try {
			Get-ChildItem -LiteralPath "$($certificateStoreLocation.PSPath)\My" -CodeSigningCert
		}
		catch {
		}
	}
}

#endregion

#region Create the Sign File command.

if (-not ($signFileCommand = $se.Commands['ScriptSigningCommand.SignFile'])) {
	$signFileCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'ScriptSigningCommand','SignFile'
	$signFileCommand.Text = 'Sign &File...'
	$signFileCommand.AddShortcut('Ctrl+Shift+F')
	$signFileCommand.Image = $imageLibrary['SignScriptImage16']
	$signFileCommand.ScriptBlock = {
		if (-not ($se.CurrentDocumentWindow | Get-Member -Name Document -ErrorAction SilentlyContinue)) {
			return
		}
		if (-not ($availableScriptSigningCertificates = @(Get-ScriptSigningCertificate))) {
			[System.Windows.Forms.MessageBox]::Show("The current document cannot be signed because no code signing certificates were found on this system.$([System.Environment]::NewLine * 2)Install a code signing certificate in your certificate store and try again.", "Code signing certificate not found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
			return
		}
		$configPath = "${PSScriptRoot}\Add-on.ScriptSigning.config.xml"
		$scriptSigningCertificatePath = $null
		$autoSaveWhenSigning = $false
		$includeChain = 'NotRoot'
		$timestampServer = $null
		if (Test-Path -LiteralPath $configPath) {
			$configuration = Import-Clixml -Path $configPath
			$scriptSigningCertificatePath = $configuration.DefaultScriptSigningCertificatePath
			$autoSaveWhenSigning = $configuration.DefaultAutoSaveWhenSigning
			$includeChain = $configuration.DefaultIncludeChain
			$timestampServer = $configuration.DefaultTimestampServer
		}
		if ((-not $scriptSigningCertificatePath) -or
			(-not (Test-Path -LiteralPath $scriptSigningCertificatePath))) {
			$dialogResult = [System.Windows.Forms.MessageBox]::Show("You must configure script signing before you can sign any script files in the PowerGUI Script Editor.$([System.Environment]::NewLine * 2)Would you like to configure script signing now?",'Missing required configuration',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
			if ($dialogResult -eq [System.Windows.Forms.DialogResult]::No) {
				return
			}
			if ($scriptSigningOptionsCommand = $se.Commands['ScriptSigningCommand.Options']) {
				$scriptSigningOptionsCommand.Invoke()
				$availableScriptSigningCertificates = @(Get-ScriptSigningCertificate)
				if (Test-Path -LiteralPath $configPath) {
					$configuration = Import-Clixml -Path $configPath
					$scriptSigningCertificatePath = $configuration.DefaultScriptSigningCertificatePath
					$autoSaveWhenSigning = $configuration.DefaultAutoSaveWhenSigning
					$includeChain = $configuration.DefaultIncludeChain
					$timestampServer = $configuration.DefaultTimestampServer
				}
			}
		}
		if ((-not $scriptSigningCertificatePath) -or
			(-not (Test-Path -LiteralPath $scriptSigningCertificatePath))) {
			[System.Windows.Forms.MessageBox]::Show("File ""$($se.CurrentDocumentWindow.Document.Path)"" will not be signed because a valid code signing signature was not selected.",'Missing required configuration',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
			return
		}
		$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		if (-not $se.CurrentDocumentWindow.Document.IsSaved) {
			if ($autoSaveWhenSigning) {
				if ($saveCommand = $se.Commands['FileCommand.Save']) {
					$saveCommand.Invoke()
				}
			} else {
				$dialogResult = [System.Windows.Forms.MessageBox]::Show("The current document (""$($se.CurrentDocumentWindow.Title)"") must be saved before it can be signed.$([System.Environment]::NewLine * 2)Would you like to save it now?","""$($se.CurrentDocumentWindow.Title)"" is not saved",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
				if (($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) -and
					($saveCommand = $se.Commands['FileCommand.Save'])) {
					$saveCommand.Invoke()
				}
			}
		}
		if (-not $se.CurrentDocumentWindow.Document.IsSaved) {
			return
		}
		$currentSignatureInformation = Get-AuthenticodeSignature -FilePath $se.CurrentDocumentWindow.Document.Path
		if (($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::NotSupportedFileFormat) -or
			($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::UnknownError)) {
			[System.Windows.Forms.MessageBox]::Show("The current document cannot be signed.$([System.Environment]::NewLine * 2)$($currentSignatureInformation.Status): $($currentSignatureInformation.StatusMessage)",'Unable to sign file',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
			return
		}
		$scriptSigningCertificate = $null
		foreach ($item in $availableScriptSigningCertificates) {
			if ($item.PSPath -eq $scriptSigningCertificatePath) {
				$scriptSigningCertificate = $item
				break
			}
		}
		$signingParameters = @{
			    FilePath = $se.CurrentDocumentWindow.Document.Path
			 Certificate = $scriptSigningCertificate
			IncludeChain = $includeChain
		}
		if ($timestampServer) {
			$signingParameters['TimestampServer'] = $timestampServer
		}
		Set-AuthenticodeSignature @signingParameters
	}

	$se.Commands.Add($signFileCommand)
}

#endregion

#region Create the View Signature command.

if (-not ($viewSignatureCommand = $se.Commands['ScriptSigningCommand.ViewSignature'])) {
	$viewSignatureCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'ScriptSigningCommand','ViewSignature'
	$viewSignatureCommand.Text = 'View &Signature'
	$viewSignatureCommand.Image = $imageLibrary['CertificatesImage16']
	$viewSignatureCommand.ScriptBlock = {
		$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance
		if (-not $se.CurrentDocumentWindow.Document.IsSaved) {
			[System.Windows.Forms.MessageBox]::Show("The current document (""$($se.CurrentDocumentWindow.Title)"") is not saved and therefore any signature it contains is invalid.$([System.Environment]::NewLine * 2)Save and sign the file and then try again.","""$($se.CurrentDocumentWindow.Title)"" is not saved",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
			return
		}
		$currentSignatureInformation = Get-AuthenticodeSignature -FilePath $se.CurrentDocumentWindow.Document.Path
		if ($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::NotSigned) {
			[System.Windows.Forms.MessageBox]::Show("The file ""$($se.CurrentDocumentWindow.Document.Path)"" is not digitally signed.$([System.Environment]::NewLine * 2)This script will not execute on a system whose execution policy requires that the file be signed.",'File not signed',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
			return
		}
		if (($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::NotSupportedFileFormat) -or
			($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::UnknownError)) {
			[System.Windows.Forms.MessageBox]::Show("The current document type does not support signing.$([System.Environment]::NewLine * 2)$($currentSignatureInformation.Status): $($currentSignatureInformation.StatusMessage)",'Signing not supported',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
			return
		}
		if ($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::Incompatible) {
			[System.Windows.Forms.MessageBox]::Show("The signature on ""$($se.CurrentDocumentWindow.Document.Path)"" cannot be verified because it is incompatible with the current system.",'Incompatible signature',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
			return
		}
		if ($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::NotTrusted) {
			[System.Windows.Forms.MessageBox]::Show("""$($se.CurrentDocumentWindow.Document.Path)"" was signed by a publisher that is not trusted on this system.",'Untrusted publisher',[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
		}
		if ($currentSignatureInformation.Status -eq [System.Management.Automation.SignatureStatus]::HashMismatch) {
			[System.Windows.Forms.MessageBox]::Show("The contents of file ""$($se.CurrentDocumentWindow.Document.Path)"" may have been tampered with because the hash of the file does not match the hash stored in the digital signature.$([System.Environment]::NewLine * 2)This script will not execute on a system whose execution policy requires that the file be signed.","Hash mismatch in ""$(Split-Path -Path $se.CurrentDocumentWindow.Document.Path -Leaf)""",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
		}
		[PowerShellTypeExtensions.Win32ViewCertificate]::Show($currentSignatureInformation.SignerCertificate)
	}

	$se.Commands.Add($viewSignatureCommand)
}

#endregion

#region Create the Script Signing Options command.

if (-not ($scriptSigningOptionsCommand = $se.Commands['ScriptSigningCommand.Options'])) {
	$scriptSigningOptionsCommand = New-Object -TypeName Quest.PowerGUI.SDK.ItemCommand -ArgumentList 'ScriptSigningCommand','Options'
	$scriptSigningOptionsCommand.Text = 'Script Signing &Options...'
	$scriptSigningOptionsCommand.Image = $imageLibrary['SignSettingsImage16']
	$scriptSigningOptionsCommand.ScriptBlock = {
		$configPath = "${PSScriptRoot}\Add-on.ScriptSigning.config.xml"
		$scriptSigningCertificatePath = $null
		$autoSaveWhenSigning = $false
		$includeChain = 'NotRoot'
		$timestampServer = $null
		if (Test-Path -LiteralPath $configPath) {
			$configuration = Import-Clixml -Path $configPath
			$scriptSigningCertificatePath = $configuration.DefaultScriptSigningCertificatePath
			$autoSaveWhenSigning = $configuration.DefaultAutoSaveWhenSigning
			$includeChain = $configuration.DefaultIncludeChain
			$timestampServer = $configuration.DefaultTimestampServer
		}
		$optionsDialog = New-Object -TypeName Addon.ScriptSigning.ScriptSigningOptionsForm
		$optionsDialog.Image = $imageLibrary['SignSettingsImage32']
		$availableScriptSigningCertificates = @(Get-ScriptSigningCertificate)
		$defaultCertificate = -1
		if ($scriptSigningCertificatePath) {
			for ($index = 0; $index -lt $availableScriptSigningCertificates.Count; $index++) {
				if ($availableScriptSigningCertificates[$index].PSPath -eq $scriptSigningCertificatePath) {
					$defaultCertificate = $index
					break
				}
			}
		}
		$optionsDialog.LoadCertificates($availableScriptSigningCertificates,$defaultCertificate)
		$optionsDialog.IncludeChain = $includeChain
		$optionsDialog.AutoSave = $autoSaveWhenSigning
		$optionsDialog.TimestampServer = $timestampServer
		$result = $optionsDialog.ShowDialog()
		if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
			$scriptSigningCertificatePath = $null
			if ($optionsDialog.DefaultCertificate -ge 0) {
				$scriptSigningCertificatePath = $availableScriptSigningCertificates[$optionsDialog.DefaultCertificate].PSPath
			}
			$configuration = @{
				DefaultScriptSigningCertificatePath = $scriptSigningCertificatePath
								DefaultIncludeChain = [string]$optionsDialog.IncludeChain
							DefaultTimestampServer = $optionsDialog.TimestampServer
						DefaultAutoSaveWhenSigning = $optionsDialog.AutoSave
			}
			Export-Clixml -Force -InputObject $configuration -Path $configPath
		}
	}

	$se.Commands.Add($scriptSigningOptionsCommand)
}

#endregion

#region Create the Script Signing menu if it does not exist.

if (-not ($scriptSigningMenu = $se.Menus['MenuBar.ScriptSigning'])) {
	$scriptSigningMenuCommand = New-Object -TypeName Quest.PowerGUI.SDK.MenuCommand -ArgumentList 'MenuBar','ScriptSigning'
	$scriptSigningMenuCommand.Text = 'Script &Signing'
	$index = -1;
	if ($toolsMenu = $se.Menus['MenuBar.Tools']) {
		$index = $se.Menus.IndexOf($toolsMenu)
	} elseif ($helpMenu = $se.Menus['MenuBar.Help']) {
		$index = $se.Menus.IndexOf($helpMenu)
	}
	if ($index -ge 0) {
		$se.Menus.Insert($index,$scriptSigningMenuCommand)
	} else {
		$se.Menus.Add($scriptSigningMenuCommand)
	}
	$scriptSigningMenu = $se.Menus['MenuBar.ScriptSigning']
}

#endregion

#region Add the menu items to the Script Signing menu.

if (-not ($signFileMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.SignFile'])) {
	$scriptSigningMenu.Items.Add($signFileCommand)
}
if (-not ($viewSignatureMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.ViewSignature'])) {
	$scriptSigningMenu.Items.Add($viewSignatureCommand)
}
if (-not ($scriptSigningOptionsMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.Options'])) {
	$scriptSigningMenu.Items.Add($scriptSigningOptionsCommand)
	if ($scriptSigningOptionsMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.Options']) {
		$scriptSigningOptionsMenuItem.FirstInGroup = $true
	}
}

#endregion

#region Create the Script Signing toolbar if it does not exist.

$scriptSigningToolbar = $null
foreach ($item in $se.Toolbars) {
	if ($item.Title -eq 'Script Signing') {
		$scriptSigningToolbar = $item
		break
	}
}
if (-not $scriptSigningToolbar) {
	$scriptSigningToolbar = New-Object -TypeName Quest.PowerGUI.SDK.Toolbar -ArgumentList 'Script Signing'
	$scriptSigningToolbar.Visible = $true
	$se.Toolbars.Add($scriptSigningToolbar)
}

#endregion

#region Add the buttons to the Script Signing toolbar.

if (-not ($signFileButton = $scriptSigningToolbar.Items['ScriptSigningCommand.SignFile'])) {
	$scriptSigningToolbar.Items.Add($signFileCommand)
}
if (-not ($viewSignatureButton = $scriptSigningToolbar.Items['ScriptSigningCommand.ViewSignature'])) {
	$scriptSigningToolbar.Items.Add($viewSignatureCommand)
}
if (-not ($scriptSigningOptionsToolbarButton = $scriptSigningToolbar.Items['ScriptSigningCommand.Options'])) {
	$scriptSigningToolbar.Items.Add($scriptSigningOptionsCommand)
	if ($scriptSigningOptionsToolbarButton = $scriptSigningToolbar.Items['ScriptSigningCommand.Options']) {
		$scriptSigningOptionsToolbarButton.FirstInGroup = $true
	}
}

#endregion

#region Clean-up the Add-on when it is removed.

$ExecutionContext.SessionState.Module.OnRemove = {
	$se = [Quest.PowerGUI.SDK.ScriptEditorFactory]::CurrentInstance

	#region Clean-up the Script Signing menu.

	if ($scriptSigningMenu = $se.Menus['MenuBar.ScriptSigning']) {
		if ($scriptSigningOptionsMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.Options']) {
			$scriptSigningMenu.Items.Remove($scriptSigningOptionsMenuItem) | Out-Null
		}
		if ($viewSignatureMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.ViewSignature']) {
			$scriptSigningMenu.Items.Remove($viewSignatureMenuItem) | Out-Null
		}
		if ($signFileMenuItem = $scriptSigningMenu.Items['ScriptSigningCommand.SignFile']) {
			$scriptSigningMenu.Items.Remove($signFileMenuItem) | Out-Null
		}
		if ($scriptSigningMenu.Items.Count -eq 0) {
			$se.Menus.Remove($scriptSigningMenu) | Out-Null
		}
	}

	#endregion

	#region Clean-up the Script Signing toolbar.

	$scriptSigningToolbar = $null
	foreach ($item in $se.Toolbars) {
		if ($item.Title -eq 'Script Signing') {
			$scriptSigningToolbar = $item
			break
		}
	}
	if ($scriptSigningToolbar) {
		if ($scriptSigningOptionsButton = $scriptSigningToolbar.Items['ScriptSigningCommand.Options']) {
			$scriptSigningToolbar.Items.Remove($scriptSigningOptionsButton) | Out-Null
		}
		if ($viewSignatureButton = $scriptSigningToolbar.Items['ScriptSigningCommand.ViewSignature']) {
			$scriptSigningToolbar.Items.Remove($viewSignatureButton) | Out-Null
		}
		if ($signFileButton = $scriptSigningToolbar.Items['ScriptSigningCommand.SignFile']) {
			$scriptSigningToolbar.Items.Remove($signFileButton) | Out-Null
		}
		if ($scriptSigningToolbar.Items.Count -eq 0) {
			$se.Toolbars.Remove($scriptSigningToolbar) | Out-Null
		}
	}

	#endregion

	#region Clean-up the Script Signing commands.

	if ($scriptSigningOptionsCommand = $se.Commands['ScriptSigningCommand.Options']) {
		$se.Commands.Remove($scriptSigningOptionsCommand) | Out-Null
	}
	if ($viewSignatureCommand = $se.Commands['ScriptSigningCommand.ViewSignature']) {
		$se.Commands.Remove($viewSignatureCommand) | Out-Null
	}
	if ($signFileCommand = $se.Commands['ScriptSigningCommand.SignFile']) {
		$se.Commands.Remove($signFileCommand) | Out-Null
	}
	if ((-not $se.Menus['MenuBar.ScriptSigning']) -and
	    ($scriptSigningMenuCommand = $se.Commands['MenuBar.ScriptSigning'])) {
		$se.Commands.Remove($scriptSigningMenuCommand) | Out-Null
	}

	#endregion
}

#endregion

# SIG # Begin signature block
# MIIdfwYJKoZIhvcNAQcCoIIdcDCCHWwCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+2qIjLQJ2mpfnn7ujha0CMVR
# H3mgghi8MIIDdTCCAl2gAwIBAgILBAAAAAABFUtaw5QwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw05ODA5
# MDExMjAwMDBaFw0yODAxMjgxMjAwMDBaMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENBMRswGQYDVQQDExJH
# bG9iYWxTaWduIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDaDuaZjc6j40+Kfvvxi4Mla+pIH/EqsLmVEQS98GPR4mdmzxzdzxtIK+6NiY6a
# rymAZavpxy0Sy6scTHAHoT0KMM0VjU/43dSMUBUc71DuxC73/OlS8pF94G3VNTCO
# XkNz8kHp1Wrjsok6Vjk4bwY8iGlbKk3Fp1S4bInMm/k8yuX9ifUSPJJ4ltbcdG6T
# RGHRjcdGsnUOhugZitVtbNV4FpWi6cgKOOvyJBNPc1STE4U6G7weNLWLBYy5d4ux
# 2x8gkasJU26Qzns3dLlwR5EiUWMWea6xrkEmCMgZK9FGqkjWZCrXgzT/LCrBbBlD
# SgeF59N89iFo7+ryUp9/k5DPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
# HRMBAf8EBTADAQH/MB0GA1UdDgQWBBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkq
# hkiG9w0BAQUFAAOCAQEA1nPnfE920I2/7LqivjTFKDK1fPxsnCwrvQmeU79rXqoR
# SLblCKOzyj1hTdNGCbM+w6DjY1Ub8rrvrTnhQ7k4o+YviiY776BQVvnGCv04zcQL
# cFGUl5gE38NflNUVyRRBnMRddWQVDf9VMOyGj/8N7yy5Y0b2qvzfvGn9LhJIZJrg
# lfCm7ymPAbEVtQwdpf5pLGkkeB6zpxxxYu7KyJesF12KwvhHhm4qxFYxldBniYUr
# +WymXUadDKqC5JlR3XC321Y9YeRq4VzW9v493kHMB65jUr9TU/Qr6cf9tveCX4XS
# QRjbgbMEHMUfpIBvFSDJ3gyICh3WZlXi/EjJKSZp4DCCBAcwggLvoAMCAQICCwEA
# AAAAAR5GQJ02MA0GCSqGSIb3DQEBBQUAMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYD
# VQQDExhHbG9iYWxTaWduIE9iamVjdFNpZ24gQ0EwHhcNMDgxMjE3MTc0ODAyWhcN
# MTExMjE3MTc0ODAyWjBhMQswCQYDVQQGEwJVUzEXMBUGA1UEChMOUXVlc3QgU29m
# dHdhcmUxFzAVBgNVBAMTDlF1ZXN0IFNvZnR3YXJlMSAwHgYJKoZIhvcNAQkBFhFz
# dXBwb3J0QHF1ZXN0LmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1mza
# 2hKiiqZnaF1sHhuFRS7MEGq9tYhF7AFbJRvTvhCZk9sxK92thKBFyDSOzJauB7Zt
# j+1HwQzpqbbU94EsR09JOf8vB+xQKLCxaBP5YjwhjJzVy+1d6frVWYN1oVxPXRBM
# G7BnFgfRkOdtsg/Qn1Uqn1ENSozyjTuh5iduUy0CAwEAAaOCAUAwggE8MB8GA1Ud
# IwQYMBaAFNJb80smS6Ww5139Vn/28S44TlOgME4GCCsGAQUFBwEBBEIwQDA+Bggr
# BgEFBQcwAoYyaHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLm5ldC9jYWNlcnQvT2Jq
# ZWN0U2lnbi5jcnQwOQYDVR0fBDIwMDAuoCygKoYoaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9PYmplY3RTaWduLmNybDAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIH
# gDATBgNVHSUEDDAKBggrBgEFBQcDAzBLBgNVHSAERDBCMEAGCSsGAQQBoDIBMjAz
# MDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdsb2JhbHNpZ24ubmV0L3JlcG9zaXRv
# cnkvMBEGCWCGSAGG+EIBAQQEAwIEEDANBgkqhkiG9w0BAQUFAAOCAQEAG9hUuQek
# ddDJ/pzfqo9p4hzKBkeKcVsunEeTUMNg90XzgdOYRFJPCD7T+gXXrTs6Y2xFmLJN
# G/2lQsjQ/32cBBN9zZdbX+ExhFfEV9/w0gbw3H/PfYkCRvp9VZlTafIt4MJCt/Zp
# guPQgggpWadScg7jQNyeHEg6H6c3WHO8PMiKcKJp9LuM1PKX9Bjy6F2k8rbdEAyJ
# u0mIiAcnEAc/KwoKBZVT1gnT3rkwgTgNlXw2hqT/Zcf8Jy4IDzbKzL+gYmDCNaju
# wAzhzaA05oZTLwhFV1sdc5MSJVJnMJVLpNO1jrhi5g6Oo6EmezM/kE8nzoXbmTlP
# JjOApuATvUdFlzCCBA0wggL1oAMCAQICCwQAAAAAASOeD6yzMA0GCSqGSIb3DQEB
# BQUAMFcxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAw
# DgYDVQQLEwdSb290IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcN
# OTkwMTI4MTMwMDAwWhcNMTcwMTI3MTIwMDAwWjCBgTELMAkGA1UEBhMCQkUxGTAX
# BgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExJTAjBgNVBAsTHFByaW1hcnkgT2JqZWN0
# IFB1Ymxpc2hpbmcgQ0ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gUHJpbWFyeSBPYmpl
# Y3QgUHVibGlzaGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AKKbdSqnE7oJcSQY36EGYikSntyedXPo31ZXaZYTVk/yyLwBWO0mhnILYPUZxVUD
# V5u5EMmh1HRA/2wA6OZTN/632nk+uFI46YEsnw4zUqbNcM5KXWL00WdevJdKB8q8
# 3Y1Hsc3xZVuFAbBLa97Nji71UOijnJ0mmGs2Y0EDcETwX+IldXlQfV+hBqJGDFWV
# RxTTkUaGaJnnJ/SU7JpBUfeW1HqM4USXaHED2FhvvbQQQu4NZnVGi0SW0jAAEgdj
# 90SbAXDKVm+cWJcqJxeLLnFSbUarpysPfxZIZMhS+gYXAAd010WzDPV4lXPoCu7E
# 4HKMHhGqHrtezvm0AO5zvc0CAwEAAaOBrjCBqzAOBgNVHQ8BAf8EBAMCAQYwDwYD
# VR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUFVF5GnwMWfnazdjEOhOayXgtf00wMwYD
# VR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxzaWduLm5ldC9Sb290LmNy
# bDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAWgBRge2YaRQ2XyolQL30E
# zTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAtXimonwEt3/Jf31qvHH6KTBgwvRi
# Hv5/Qx6bbuKyH3MLhXZbffVOSQYv1Pq3kUDv7W+NjhODVMUqAj0KpNyZC3q9dy/M
# QMGP88SMTnK6EHzm/2Qrx85sp/zXmnyORo0Bg01CO9ucP58yYVfXF7CzNmbws/1E
# b4E3sZROp1YlifWK1m0RYmJ5XEKQAhjTnCP8COhkRbktfoBbTq/DiimSg3gfkUE0
# r4XF/QeZTixc/sf9F7slJTFNcrW1KUtImjdvE8cRTkpFHn4vMZyr6FKv1meXNIhf
# DidqZlLRWsesMCwgON0r/zrrzhBFgqJ7G6Egc1abKpPmBFEGbBvcL4mUkzCCBBow
# ggMCoAMCAQICCwQAAAAAASAZwZBmMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNVBAYT
# AkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290IENB
# MRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMDkwMzE4MTEwMDAwWhcN
# MjgwMTI4MTIwMDAwWjBUMRgwFgYDVQQLEw9UaW1lc3RhbXBpbmcgQ0ExEzARBgNV
# BAoTCkdsb2JhbFNpZ24xIzAhBgNVBAMTGkdsb2JhbFNpZ24gVGltZXN0YW1waW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwwy3Eg1NaIoz3jYF
# 8Dy69drNDlN7Rp+C8mIT18F3rbuBN35PHpOBwQYi2h1QhMaXlZKpk7Y9q4Z5GVR9
# DhYETMSIlyzGoahfFTrSZCvMPgx66KRWsR67z4TOjTU6NJxsLcB3tTCpH2fmOglE
# OkNyQaKRw0aaH7a5pw+vHHUbZCXnCGwUR/VHGt6O6qJjlX31qK1VomSbcm+5AnM/
# OYo5XMT+j/sRnL0QGUlj0EMii9arkpl0FM8wB75Pvf2Kj55a3208zFqZUJC5rcKX
# Q8Jf7c0zPYfMwaBbqWI7eH1ko6xNHyvXAxFscVSKsKuxHNZ9I9tABzcm21CvOD2m
# B3VvlwIDAQABo4HpMIHmMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBTowvHEMtwzNTe8ZXb1nBcuF0Us/jBLBgNVHSAERDBCMEAG
# CSsGAQQBoDIBHjAzMDEGCCsGAQUFBwIBFiVodHRwOi8vd3d3Lmdsb2JhbHNpZ24u
# bmV0L3JlcG9zaXRvcnkvMDMGA1UdHwQsMCowKKAmoCSGImh0dHA6Ly9jcmwuZ2xv
# YmFsc2lnbi5uZXQvcm9vdC5jcmwwHwYDVR0jBBgwFoAUYHtmGkUNl8qJUC99BM00
# qP/8/UswDQYJKoZIhvcNAQEFBQADggEBAF32yysNAUCEn4V6Q3Bq4MXnqgYA12cT
# yQiRMWVPFKipBdw4nmqgMAq9jceAKO5CRcqU895YRamAMgT1WVxqcAA5J5RN9bRG
# NOgcUzGys1QW6cxCq9XZWTAc+0YnJbiHI7HodYgkgx7Idjd7AUlFSKTt4l3SfJyi
# 3C26EFoSYmWrrgDHEDQ7y3K9FCQM3MN2J7Sn/uFYKfIOFp+ROR2JpuYPHIeM4lis
# kn4kPqrsFOc6MzSLxjusg6sPFGJ6uhotTUsbxTDwC5J5fTx44Pjm0hWWWZk5KzBh
# 6Lj4wKHpIhQReH3E3Im+wLuU4XKu67VAQE/vFx5YXtCoiZaskijpur8wggQuMIID
# FqADAgECAgsBAAAAAAElsLTMATANBgkqhkiG9w0BAQUFADBUMRgwFgYDVQQLEw9U
# aW1lc3RhbXBpbmcgQ0ExEzARBgNVBAoTCkdsb2JhbFNpZ24xIzAhBgNVBAMTGkds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBMB4XDTA5MTIyMTA5MzI1NloXDTIwMTIy
# MjA5MzI1NlowUjELMAkGA1UEBhMCQkUxFjAUBgNVBAoTDUdsb2JhbFNpZ24gTlYx
# KzApBgNVBAMTIkdsb2JhbFNpZ24gVGltZSBTdGFtcGluZyBBdXRob3JpdHkwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNwj1ddyLQwn04MsMVgx9CajtT
# Zt1qNkQNac9ojYlFn34v7kI6M3w+ANOXatha1cNNkgpfBlD9v2zEA6KCYNjtUi4T
# dN6XxkUhe1X26rFkA/x0a7Jfx2xsQxSKJBA3SZWB0kgSpaJ2SVAhf8qFcwo8XbUu
# rZCqXk0yyxeT2X+WwMCJZVbZxbE/mBsn+knuHRvLBowwHDvFp3BbqKsYWv7I9o6/
# AV2PYZg0D1hR/98y6lRlHBQrbPwMkBln7ZvZ2mOb1loko3SOCCMAoZK1HgvRCKBm
# f5Ibo+2AZAJJj7aE79FVjl6pl1rFCAKIlFa/kusqLQY1krU3NjHsw/56O8KFAgMB
# AAGjggEBMIH+MB8GA1UdIwQYMBaAFOjC8cQy3DM1N7xldvWcFy4XRSz+MDwGA1Ud
# HwQ1MDMwMaAvoC2GK2h0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvVGltZXN0YW1w
# aW5nMS5jcmwwHQYDVR0OBBYEFKqqporvpGRz1pXieciP6s+lYCnKMAkGA1UdEwQC
# MAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEsGA1Ud
# IAREMEIwQAYJKwYBBAGgMgEeMDMwMQYIKwYBBQUHAgEWJWh0dHA6Ly93d3cuZ2xv
# YmFsc2lnbi5uZXQvcmVwb3NpdG9yeS8wDQYJKoZIhvcNAQEFBQADggEBALyJ7P7m
# NlWTXHnUEXqGgI8XtpOybZuRoVYYEcZV6vYI7a2bnvUrgci73WB7G0eZHm1APh2A
# whPVjgQFL9vnrlKeaIRyoeVKYDz4m9UvRtjDsreTU6ybbEMkJNHx/OlWLjQRWBhD
# 6u//NHRsoMBsf60DGWmIHpVgyru9DLt278cksIHGODHPNq0MOLiQIISbLo8ouZ/2
# ypQnzaw5YVfg45VanHaSMPXeppc9chwqYDKoM02GNTOKXPOk/fcGLOFrSzD1y9ND
# YvhBud59IMsFjI4s9l81/TONQollCDYso4n0WoWLsLl722zLofjSDhu7l3zRJ3m+
# nXw75qdWNNjJkakwggTTMIIDu6ADAgECAgsEAAAAAAEjng+vJDANBgkqhkiG9w0B
# AQUFADCBgTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# JTAjBgNVBAsTHFByaW1hcnkgT2JqZWN0IFB1Ymxpc2hpbmcgQ0ExMDAuBgNVBAMT
# J0dsb2JhbFNpZ24gUHJpbWFyeSBPYmplY3QgUHVibGlzaGluZyBDQTAeFw0wNDAx
# MjIxMDAwMDBaFw0xNzAxMjcxMDAwMDBaMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYD
# VQQDExhHbG9iYWxTaWduIE9iamVjdFNpZ24gQ0EwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQCwsfKAAHDO7MOMtJftxgmMJm+J32dZgc/eFBNMwrFF4lN1
# QfoHNm+6EXAolHxtcr0HFSVlOgn/hdz6e143hzjkx0sIgJieis1YCQLAwwFJlliI
# iSZZ9W3GucH7GCXt2GJOygpsXXDvztObKQsJxvbuthbUPFSOzF3gr9vdIwkyezKB
# FmIKBst6zzQhtm82trHOy5opNUA+nVh8/62CmPq41YnKNd3LzVcGy5vkv5SogJhf
# d5bwtuerdHlAIaZj6dAHkb2FOLSulqyh/xRz2qVFuE2Gzio879TfKA51qaiIE8Lk
# fGCT8iXMA4SX5k62ny3WtYs0PKvVODrIPcSx+ZTNAgMBAAGjggFnMIIBYzAOBgNV
# HQ8BAf8EBAMCAQYwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU0lvzSyZL
# pbDnXf1Wf/bxLjhOU6AwSgYDVR0gBEMwQTA/BgkrBgEEAaAyATIwMjAwBggrBgEF
# BQcCARYkaHR0cDovL3d3dy5nbG9iYWxzaWduLm5ldC9yZXBvc2l0b3J5MDkGA1Ud
# HwQyMDAwLqAsoCqGKGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5uZXQvcHJpbW9iamVj
# dC5jcmwwTgYIKwYBBQUHAQEEQjBAMD4GCCsGAQUFBzAChjJodHRwOi8vc2VjdXJl
# Lmdsb2JhbHNpZ24ubmV0L2NhY2VydC9QcmltT2JqZWN0LmNydDARBglghkgBhvhC
# AQEEBAMCAAEwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHwYDVR0jBBgwFoAUFVF5GnwM
# WfnazdjEOhOayXgtf00wDQYJKoZIhvcNAQEFBQADggEBAB5q8230jqki/nAIZS6h
# XaszMN1sePpL6q3FjewQemrFWJc5a5LzkeIMpygc0V12josHfBNvrcQ2Q7PBvDFZ
# zxg42KM7zv/KZ1i/4PGsYT6iOx68AltBrERr9Sbz7V6oZfbKZaY/yvV366WGKlgp
# Vvi+FhBA6dL8VyxjYTdmJTkgLgcDoDYDJZS9fOt+06PCxXYWdTCSuf92QTUhaNEO
# XlyOwwNg5oBA/MBdolRubpJnp4ESh6KjK9u3Tf/k1cflBebV8a78zWYYIfM+R8nl
# lUJhLJ0mgLIPqD0Oyad43250jCxG9nLpPGRrKFXES2Qzy3hUEzjw1XEG1D4NCjUO
# 4LMxggQtMIIEKQIBATByMGMxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxT
# aWduIG52LXNhMRYwFAYDVQQLEw1PYmplY3RTaWduIENBMSEwHwYDVQQDExhHbG9i
# YWxTaWduIE9iamVjdFNpZ24gQ0ECCwEAAAAAAR5GQJ02MAkGBSsOAwIaBQCgeDAY
# BgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3
# AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEW
# BBTDh4Qb74AkMXnoEytSIeQCdfwgzDANBgkqhkiG9w0BAQEFAASBgDn5MmtWI71F
# os1SCEXXADuDEMD41aJ8f177PmUKWeHoGBwFpOtFCl8cCxzuvBOR8atH47JMCm41
# YOQHIo+qX0I/7YfhMbrx1LctNkf27CQj7P4vuWLTbyQHHGhoLW8knHuaLQvEFAv9
# +6f6gltl54RyFxpVf+xiT6FlbJc2ltnfoYIClzCCApMGCSqGSIb3DQEJBjGCAoQw
# ggKAAgEBMGMwVDEYMBYGA1UECxMPVGltZXN0YW1waW5nIENBMRMwEQYDVQQKEwpH
# bG9iYWxTaWduMSMwIQYDVQQDExpHbG9iYWxTaWduIFRpbWVzdGFtcGluZyBDQQIL
# AQAAAAABJbC0zAEwCQYFKw4DAhoFAKCB9zAYBgkqhkiG9w0BCQMxCwYJKoZIhvcN
# AQcBMBwGCSqGSIb3DQEJBTEPFw0xMDEwMTkxODUyNThaMCMGCSqGSIb3DQEJBDEW
# BBRQRRdjVEOJvoUTz1U2iiRXP2+CEzCBlwYLKoZIhvcNAQkQAgwxgYcwgYQwgYEw
# fwQUrt9992u6JBDWfbrxj1uhW0F+SWwwZzBYpFYwVDEYMBYGA1UECxMPVGltZXN0
# YW1waW5nIENBMRMwEQYDVQQKEwpHbG9iYWxTaWduMSMwIQYDVQQDExpHbG9iYWxT
# aWduIFRpbWVzdGFtcGluZyBDQQILAQAAAAABJbC0zAEwDQYJKoZIhvcNAQEBBQAE
# ggEAmA9ixwgi1FOCSdxRL1hYya13+/guXlicEVE4HWsR+IcRP7zmvOyy5OexEj94
# Z6hTVtypj9nKslKq7uwpHcAOSBdLLL8ZyXBeAjrGjXa8LTbFiWv/K3divr8rqPvZ
# Uh+tm8NcUNbPanvgqK1t/IXyk18+IMfgwiRQW1xaTA/XHLQ7WiJ7UfcEe705+/kT
# M2OItD8InhByfXJRpRubJY9+IZSUqqW28Tiu2CWB0VWV69h51iHK0NG9nMvg8Z6+
# k0v9CFCHz2ucyUfR3w0Tv3O/mADEdlPtEn+OYCfwt/R1YAIOPcucm8RUpCTCwm5Z
# tid0l/t13yAJ3eAhyFRe/BCS/Q==
# SIG # End signature block
