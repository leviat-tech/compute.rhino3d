using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using Nancy;
using Nancy.Responses;
using Newtonsoft.Json;
using Rhino.FileIO;

namespace compute.geometry
{
    public class FileEndPointsModule : NancyModule
    {
        public FileEndPointsModule(Nancy.Routing.IRouteCacheProvider routeCacheProvider)
        {
            Post["exportstep"] = _ => Export(Context, "STP");
        }

        static Response Export(NancyContext ctx, string extension)
        {
            string requestId = ctx.Request.Headers["X-Compute-Id"].FirstOrDefault() as string;
            var stashDir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "Compute", "Requests");
            string attachmentDir = Path.Combine(stashDir, requestId);
            DirectoryInfo d = new DirectoryInfo(attachmentDir);
            FileInfo[] attachments = d.GetFiles("*.3dm");
            var firstAttachment = attachments.FirstOrDefault();

            if (firstAttachment == null)
                throw new Exception("No 3dm attachment found.");

            var doc = Rhino.RhinoDoc.Load(firstAttachment.FullName);

            string outputPath;
            switch (extension)
            {
                case "STP":
                    outputPath = ExportStep(doc);
                    break;
                default:
                    throw new Exception("Extension not implemented.");
            }
            var outputFile = new FileStream(outputPath, FileMode.Open);
            var outputName = Path.ChangeExtension(Path.GetFileName(outputPath), "stp");

            var response = new StreamResponse(() => outputFile, MimeTypes.GetMimeType(outputName));
            return response.AsAttachment(outputName);
        }

        static string ExportStep(Rhino.RhinoDoc doc)
        {
            string docPath = doc.Path;
            string stepPath = Path.ChangeExtension(docPath, "stp");
            var step = Rhino.FileIO.FileStp.Write(stepPath, doc, new Rhino.FileIO.FileStpWriteOptions());
            doc.Dispose();
            if (step)
            { return stepPath; }
            else
            { throw new Exception("STEP conversion failed"); }
        }

    }
}

