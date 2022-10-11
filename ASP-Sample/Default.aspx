<%@ Page Title="SigCaptX Sample" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="ASP_Sample._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" style="margin: 0px; width: 770px; height: 100%" runat="server">


    <style type="text/css">
        img {
            margin-left: 109px;
        }
    </style>
    <!-- Load the sigcaptX JS -->
    <script src="Scripts/wgssSigCaptX.js" type="text/javascript"></script>
    <script src="Scripts/base64.js" type="text/javascript"></script>
    <script src="Content/axios.js"></script>
    <link href="Content/SingnatureStyle.css" rel="stylesheet" />
    <!-- Create the port checking JS -->
    <script type="text/javascript" id="signature">

        var ResultImageSignture;
        debugger;

        var PathSplitURL = window.location.href
        var CASEID = PathSplitURL ? PathSplitURL.split('=')[1] : "";



        function OUT_REFRESH_ATT(siebleCaseId) {
            debugger;

            SiebelApp = top.parent.SiebelApp;
            var app = top.parent.SiebelApp.S_App;
            var sBusService = SiebelApp.S_App.GetService("Workflow Process Manager");

            if (sBusService) {
                //Create new property set
                var Inputs = SiebelApp.S_App.NewPropertySet();
                var Outputs = SiebelApp.S_App.NewPropertySet();

                /* log */
                console.log('================OUT_REFRESH_ATT================')

                console.log("Object Id", siebleCaseId);

                /* end log */


                Inputs.SetProperty("ProcessName", 'OUT Refresh Attachment WF');
                Inputs.SetProperty("Object Id", siebleCaseId);

                //sFingerOwner

                // Invoke the Business service Method and pass the Inputs
                Outputs = sBusService.InvokeMethod("RunProcess", Inputs);

                console.log(Outputs);
                // Get the Outputs/Result Set in a property set
                //var ResultSet = SiebelApp.S_App.NewPropertySet();
                //ResultSet = oups.GetChildByType ("result");
            }
            else {
                alert("Business Service Refresh Not Found");
            }
        }

        //This prints output to the text field on the page
        function print(txt) {

            var txtDisplay = document.getElementById("txtDisplay");
            if ("CLEAR" == txt) {
                txtDisplay.value = "";
            }
            else {
                txtDisplay.value += txt + "\n";
                txtDisplay.scrollTop = txtDisplay.scrollHeight; // scroll to end
            }
        }

        var wgssSignatureSDK;
        var sigObj = null;
        var sigCtl = null;
        var dynCapt = null;
        var l_name = null;
        var l_reason = null;
        var l_imageBox = null;

        //Assumes the default host / port for sig captX (localhost, 8000). Checks for sigcapt service.  Called from Default.aspx.cs
        function startSession() {
            print("Detecting SigCaptX");

            wgssSignatureSDK = new WacomGSS_SignatureSDK(onDetectRunning, 8000);

            function onDetectRunning() {
                print("SigCaptX detected");
                clearTimeout(timeout);
            }

            var timeout = setTimeout(timedDetect, 1500);
            function timedDetect() {
                if (wgssSignatureSDK.running) {
                    print("SigCaptX detected");
                }
                else {
                    if (wgssSignatureSDK.service_detected) {
                        print("SigCaptX service detected, but not the server");
                    }
                    else {
                        print("SigCaptX service not detected");
                    }
                }
            }
        }

        //Reset the session for signature capture
        function restartSession(callback) {
            //First, reset the objects 
            wgssSignatureSDK = null;
            sigCtl = null;
            sigObj = null;
            dynCapt = null;

            var timeout = setTimeout(timedDetect, 1500);

            //Startup the SDK - assumes default port
            wgssSignatureSDK = new WacomGSS_SignatureSDK(onDetectRunning, 8000);

            function timedDetect() {
                if (wgssSignatureSDK.running) {
                    print("Signature SDK Service detected.");
                    start();
                }
                else {
                    print("Signature SDK Service not detected.");
                }
            }


            function onDetectRunning() {
                if (wgssSignatureSDK.running) {
                    print("Signature SDK Service detected.");
                    clearTimeout(timeout);
                    start();
                }
                else {
                    print("Signature SDK Service not detected.");
                }
            }

            function start() {
                if (wgssSignatureSDK.running) {
                    sigCtl = new wgssSignatureSDK.SigCtl(onSigCtlConstructor);
                }
            }

            function onSigCtlConstructor(sigCtlV, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    // Insert license here:
                    sigCtl.PutLicence("eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJMTVMiLCJleHAiOjE2NjkyOTI4NzAsImlhdCI6MTY2MTM0NDA3MCwic2VhdHMiOjAsInJpZ2h0cyI6WyJTSUdfU0RLX0NPUkUiLCJUT1VDSF9TSUdOQVRVUkVfRU5BQkxFRCIsIlNJR0NBUFRYX0FDQ0VTUyIsIlNJR19TREtfSVNPIiwiU0lHX1NES19FTkNSWVBUSU9OIl0sImRldmljZXMiOltdLCJ0eXBlIjoiZXZhbCIsImxpY19uYW1lIjoiV2Fjb21fSW5rX1NES19mb3Jfc2lnbmF0dXJlIiwid2Fjb21faWQiOiI3ZjJlOWU0MGMwNWY0NDYwOTRkNWE5YmRjOGU5ZDg0OCIsImxpY191aWQiOiI1Y2MwODk3YS0zMTkxLTQ2OTktYmIzNC04MWQ5ZGQ1YWFiMjciLCJhcHBzX3dpbmRvd3MiOltdLCJhcHBzX2lvcyI6W10sImFwcHNfYW5kcm9pZCI6W10sIm1hY2hpbmVfaWRzIjpbXX0.eE1db_Tp8Ka-8VM86GUVMpZtNXuy7mxrN2m8mXCQ91-ZSo82gUitQF8oT3GY4tt58oAMIH0QsgkwLdQuKXotcEdXsXMhqJf1HO3PIOCVMX17sLYztXGsZ9qajIL0tqfUTsxCzjKxiPBUnSyW2dz3EEyPKuncduAZd5OEMxqUqeuuy7FCVI8aGtfm6c-zMFbOEL1_ejqtSk1AqmjM71gUsK92y1RX2yP2wXrtC0THJwAfwQbVJqf2HRo8XzVNZ43gzYAxCdRxyrichhGpIFCnJn7Do791S7CQW6l0ZDIGg7-7Oy6tRJwVpVBYEbVIUg9VvRXjZ0scnkAiAsHD1h0dAQ", onSigCtlPutLicence);
                }
                else {
                    print("SigCtl constructor error: " + status);
                }
            }

            function onSigCtlPutLicence(sigCtlV, status) {
                debugger;
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    dynCapt = new wgssSignatureSDK.DynamicCapture(onDynCaptConstructor);
                }
                else {
                    print("SigCtl constructor error: " + status);
                }
            }

            function onDynCaptConstructor(dynCaptV, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    sigCtl.GetSignature(onGetSignature);
                }
                else {
                    print("DynCapt constructor error: " + status);
                }
            }

            function onGetSignature(sigCtlV, sigObjV, status) {
                debugger;
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    sigObj = sigObjV;
                    sigCtl.GetProperty("Component_FileVersion", onSigCtlGetProperty);
                }
                else {
                    print("SigCapt GetSignature error: " + status);
                }
            }

            function onSigCtlGetProperty(sigCtlV, property, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    print("DLL: flSigCOM.dll  v" + property.text);
                    dynCapt.GetProperty("Component_FileVersion", onDynCaptGetProperty);
                }
                else {
                    print("SigCtl GetProperty error: " + status);
                }
            }

            function onDynCaptGetProperty(dynCaptV, property, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    print("DLL: flSigCapt.dll v" + property.text);
                    print("Test application ready.");
                    print("Press 'Start' to capture a signature.");
                    if ('function' === typeof callback) {
                        callback();
                    }
                }
                else {
                    print("DynCapt GetProperty error: " + status);
                }
            }
        }

        function resizeBase64Img(base64, width, height) {

            var canvas = document.createElement("canvas");
            canvas.width = width;
            canvas.height = height;
            var context = canvas.getContext("2d");
            var deferred = $.Deferred();
            $("<img/>").attr("src", base64).load(function () {
                context.scale(width / this.width, height / this.height);
                context.drawImage(this, 0, 0);
                deferred.resolve($("<img/>").attr("src", canvas.toDataURL()));
            });
            return deferred.promise();
        }



        //Get Image And Save it to sebiel App
        function SaveSignture() {
            debugger;
            if (ResultImageSignture != undefined) {

                resizeBase64Img(ResultImageSignture, 250, 250).then(function (newImg) {

                    var NewImage = newImg[0].src;

                    var imagebas64 = NewImage.split(",")[1];

                    $.ajax({
                        type: 'POST',
                        url: 'Default.aspx/SaveAndGetImagesSingnature',
                        data: '{ "imageData" : "' + imagebas64 + '" , CASE_ID: "' + CASEID + '"  }',
                        contentType: 'application/json; charset=utf-8',
                        dataType: 'json',
                        success: function (imagePathRetrun) {
                            debugger;
                            ResultImageSignture = undefined;
                            
                            if (imagePathRetrun.d) {
                                try {
                                    SiebelApp = top.parent.SiebelApp;
                                    var sBusService = SiebelApp.S_App.GetService("OUT Common Business Service");

                                    if (sBusService) {
                                        //Create new property set
                                        var Inputs = SiebelApp.S_App.NewPropertySet();
                                        var Outputs = SiebelApp.S_App.NewPropertySet();
                                        /*-------LOG --------*/
                                        console.log(CASEID);
                                        /*-------------------*/
                                        Inputs.SetProperty("FilePath", imagePathRetrun.d);
                                        Inputs.SetProperty("FileDescARA", 'توقيع مقدم الطلب');
                                        Inputs.SetProperty("CaseId", CASEID);
                                        Inputs.SetProperty("RequestType", 'Case');


                                        // Invoke the Business service Method and pass the Inputs
                                        Outputs = sBusService.InvokeMethod("AddAttachmentToFileSystem", Inputs);
                                        alert("تم حفظ توقيع مقدم الطلب بنجاح");

                                        OUT_REFRESH_ATT(CASEID);


                                    }
                                    else {

                                        alert("Business Service Not Found");
                                    }

                                } catch (error) {
                                    alert("حصل خطأ في كود سيبل " + error);
                                }
                                

                            } else {
                                alert("لا يتم حفظ الصوره في المجلد")
                            }
                        },error: function (e) {

                            alert("حدث خطأ اثناء حفظ الصوره" + e)
                        }

                    });

                });


            } else {
                alert("لم يتم التوقيع بعد ")
            }

        }

        //Capture the first signature with the specified name and reason fields
        function captureSignature1(name, reason, imageBox) {
            debugger;
            l_name = name;
            l_reason = reason;
            l_imageBox = imageBox;
            Capture();
        }


        //Capture the first signature with the specified name and reason fields
        function captureSignature2(name, reason, imageBox) {
            l_name = name;
            l_reason = reason;
            l_imageBox = imageBox;
            Capture();
        }

        //Do the capture
        function Capture() {
            debugger;

            if (wgssSignatureSDK == null || !wgssSignatureSDK.running || null == dynCapt) {
                print("Session error. Restarting the session.");
                restartSession(window.Capture);
                return;
            }
            dynCapt.Capture(sigCtl, l_name, l_reason, null, null, onDynCaptCapture);

            function onDynCaptCapture(dynCaptV, SigObjV, status) {
                if (wgssSignatureSDK.ResponseStatus.INVALID_SESSION == status) {
                    print("Error: invalid session. Restarting the session.");
                    restartSession(window.Capture);
                }
                else {
                    if (wgssSignatureSDK.DynamicCaptureResult.DynCaptOK != status) {
                        print("Capture returned: " + status);
                    }
                    switch (status) {
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptOK:
                            sigObj = SigObjV;
                            print("Signature captured successfully");
                            //Produce a bitmap image with steganograpics
                            var flags = wgssSignatureSDK.RBFlags.RenderOutputBase64 |
                                wgssSignatureSDK.RBFlags.RenderEncodeData |
                                wgssSignatureSDK.RBFlags.RenderColor24BPP;

                            var imageBox = document.getElementById(l_imageBox);
                            sigObj.RenderBitmap("bmp", 250, 250, 0.7, 0x00000000, 0x00FFFFFF, flags, 0, 0, onRenderBitmap);
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptCancel:
                            print("Signature capture cancelled");
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptPadError:
                            print("No capture service available");
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptError:
                            print("Tablet Error");
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptIntegrityKeyInvalid:
                            print("The integrity key parameter is invalid (obsolete)");
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptNotLicensed:
                            print("No valid Signature Capture licence found");
                            break;
                        case wgssSignatureSDK.DynamicCaptureResult.DynCaptAbort:
                            print("Error - unable to parse document contents");
                            break;
                        default:
                            print("Capture Error " + status);
                            break;
                    }
                }
            }
        }

        ///Called when the signature image is received 
        function onRenderBitmap(sigObjV, bmpObj, status) {
            debugger;
            if (wgssSignatureSDK.ResponseStatus.OK == status) {
                ResultImageSignture = "";

                ResultImageSignture = bmpObj.image.src;
                var imageBox = document.getElementById(l_imageBox);
                if (null == imageBox.firstChild) {
                    imageBox.appendChild(bmpObj.image);
                }
                else {
                    imageBox.replaceChild(bmpObj.image, imageBox.firstChild);
                }
            }
            else {
                print("Signature Render Bitmap error: " + status);
            }

            //And get the base64 too
            sigObj.GetSigText(onGetText);
        }

        //Generate a random file name - in production, the filename could be set to transaction ID
        function guid() {
            function s4() {
                return Math.floor((1 + Math.random()) * 0x10000)
                    .toString(16)
                    .substring(1);
            }
            return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
                s4() + '-' + s4() + s4() + s4();
        }

        ///Called when the signature text is received uploads the FSS to the server and writes out the file
        function onGetText(sigObjV, text, status) {
            var name = guid();

            debugger;
            $.ajax({
                type: 'POST',
                url: 'Default.aspx/ReceivedSignatureText',
                data: '{ signature: "' + text + '", guid: "' + name + '" }',
                contentType: 'application/json; charset=utf-8',
                dataType: 'json',
                success: function (msg) {
                }
            });

            print("Sent " + name + ".txt to server as BASE64 encoded FSS");
        }

        function DisplaySignatureDetails() {
            if (!wgssSignatureSDK.running || null == sigObj) {
                print("Session error. Restarting the session.");
                restartSession(window.DisplaySignatureDetails);
                return;
            }
            sigObj.GetIsCaptured(onGetIsCaptured);

            function onGetIsCaptured(sigObj, isCaptured, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    if (!isCaptured) {
                        print("No signature has been captured yet.");
                        return;
                    }
                    sigObj.GetWho(onGetWho);
                }
                else {
                    print("Signature GetWho error: " + status);
                    if (wgssSignatureSDK.ResponseStatus.INVALID_SESSION == status) {
                        print("Session error. Restarting the session.");
                        restartSession(window.DisplaySignatureDetails);
                    }
                }
            }

            function onGetWho(sigObjV, who, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    print("  Name:   " + who);
                    var tz = wgssSignatureSDK.TimeZone.TimeLocal;
                    sigObj.GetWhen(tz, onGetWhen);
                }
                else {
                    print("Signature GetWho error: " + status);
                }
            }

            function onGetWhen(sigObjV, when, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    print("  Date:   " + when.toString());
                    sigObj.GetWhy(onGetWhy);
                }
                else {
                    print("Signature GetWhen error: " + status);
                }
            }

            function onGetWhy(sigObjV, why, status) {
                if (wgssSignatureSDK.ResponseStatus.OK == status) {
                    print("  Reason: " + why);
                }
                else {
                    print("Signature GetWhy error: " + status);
                }
            }

        }
    </script>



    <div style="width: 100%">


        <asp:UpdatePanel ID="UpdatePanel1" UpdateMode="Conditional" runat="server">
            <ContentTemplate>

                <div class="col-xs-12 col-sm-12 col-md-12 header">
                    <div class="row">
                        <div class="col-xs-6 col-sm-6 col-md-6">
                            <img src="Content/logo/IraqLogo.png" />
                        </div>
                        <div class="col-xs-6 col-sm-6 col-md-6">
                           
                         <h2 style="text-align: center;color:white">التوقيع الالكتروني</h2>
                        </div>
                        
                    </div>
                </div>

                <div class="row">
                      <table style="margin: 100px 0px 0px 300px;">

                    <tr>
                        <td rowspan="3" style="padding: 5px 10px;">
                            <div id="imageBox1" class="boxed" style="height: 255px; width: 450px;    border: 2px solid #333333;border-radius: 20px;" ondblclick="DisplaySignatureDetails1()" title="Double-click a signature to display its details">
                            </div>
                        </td>

                        <%--<td  style="padding: 5px 10px;">
            <asp:Button ID="Button1" runat="server" OnClick="CheckSigcaptX_Click" Text="Check SigCaptX" Height="30px" Width="200px"/>
          </td>--%>
                    </tr>

                    <tr>
                        <td style="padding: 5px 10px;">
                            <asp:Button Style="color: white; background: #1f3646 !important; font-size: 20px;border-radius: 12px;" ID="CaptureSignature1" runat="server" OnClick="Capture_Signature_Click1" Text="توقيـع / أعادة توقيـع" Height="54px" Width="200px" />
                            <br />
                            <br />
                            <asp:Button runat="server" ID="SaveSignture" OnClientClick="return SaveSignture();" Text="حفــظ" Style="color: white;font-size: 20px;background: #1f3646;border-radius: 12px;" Width="200px" Height="45px" />
                        </td>

                    </tr>

                    <%-- <tr>
          <td style="padding:5px 10px;">
            <asp:Button ID="Reset1" runat="server" OnClick="Reset_Click1" Text="Reset" Height="30px" Width="200px" />
          </td>

        </tr>--%>
                </table>
                </div>
              
            </ContentTemplate>
        </asp:UpdatePanel>

        <asp:UpdatePanel ID="UpdatePanel2" UpdateMode="Conditional" runat="server">
            <ContentTemplate>

                <%-- <table style="padding: 0px 0px;">
        <tr>
         <td rowspan="2" style="padding: 5px 10px;">
            <div id="imageBox2" class="boxed" style="height:40mm;width:45mm; border:1px solid #d3d3d3;" ondblclick="DisplaySignatureDetails1()" title="Double-click a signature to display its details">
            </div>
          </td>

          <td style="padding: 5px 10px;">
            <asp:Button ID="CaptureSignature2" 3OnClick="Capture_Signature_Click2" Text="Capture Second Signature"  Height="30px" Width="200px" />
          </td>
         </tr>

         <tr>
           <td style="padding:5px 10px;">
            <asp:Button ID="Reset2" runat="server" OnClick="Reset_Click2" Text="Reset" Height="30px" Width="200px" />
           </td>
         </tr>


      </table>--%>
            </ContentTemplate>
        </asp:UpdatePanel>

        <br />

        <p style="display: none">
            <asp:Label ID="NameLabel" runat="server" Text="Name: " BorderStyle="None" BorderWidth="5px" CssClass="text-primary"></asp:Label>
            <asp:TextBox ID="nameBox" Text="Polaris" runat="server" Height="30px"></asp:TextBox>
            &nbsp;<asp:Label ID="ReasonLabel" runat="server" Text="Reason: " BorderStyle="None" BorderWidth="5px" CssClass="text-primary"></asp:Label>
            <asp:TextBox ID="reasonBox" runat="server" Text="Polaris2" Height="30px"></asp:TextBox><br />

        </p>
        <div style="display: none">
            <br />
            <br />
            <textarea cols="125" rows="100" id="txtDisplay"></textarea>
        </div>

    </div>
</asp:Content>
