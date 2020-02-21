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
            Post["export/{extension}"] = _ => Export(Context, _["extension"]);
        }

        static Response Export(NancyContext ctx, string extension)
        {
            string requestId = ctx.Request.Headers["X-Compute-Id"].FirstOrDefault() as string;
            var stashDir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "Compute", "Requests");
            string attachmentDir = Path.Combine(stashDir, requestId);
            DirectoryInfo d = new DirectoryInfo(attachmentDir);
            FileInfo[] attachments = d.GetFiles("*.*");
            var firstAttachment = attachments.FirstOrDefault();

            if (firstAttachment == null)
                throw new Exception("No attachment found.");

            string outputPath;
            switch (extension.ToLower())
            {
                case "stp":
                    outputPath = ExportStep(firstAttachment.FullName, "stp");
                    break;
                default:
                    outputPath = ExportAny(firstAttachment.FullName, extension.ToLower());
                    break;
            }
            var outputFile = new FileStream(outputPath, FileMode.Open);
            var outputName = Path.ChangeExtension(Path.GetFileName(outputPath), "stp");

            var response = new StreamResponse(() => outputFile, MimeTypes.GetMimeType(outputName));
            return response.AsAttachment(outputName);
        }

        static string ExportStep(string source, string extension)
        {
            var doc = Rhino.RhinoDoc.New("");
            doc.Import(source);
            bool saved = doc.SaveAs(Path.ChangeExtension(source, "3dm"));
            doc.Dispose();
            doc = Rhino.RhinoDoc.Load(Path.ChangeExtension(source, "3dm"));
            string docPath = doc.Path;
            string exportPath = Path.ChangeExtension(docPath, "stp");
            var exported = Rhino.FileIO.FileStp.Write(exportPath, doc, new Rhino.FileIO.FileStpWriteOptions());
            doc.Dispose();
            if (exported)
            { return exportPath; }
            else
            { throw new Exception("Export failed"); }
        }

        //Many formats have issues, also binary response seems to get corrupted
        static string ExportAny(string source, string extension)
        {
            var doc = Rhino.RhinoDoc.New("");
            doc.Import(source);
            string exportPath = Path.ChangeExtension(source, extension);
            bool exported = doc.Export(exportPath);
            doc.Dispose();
            if (exported)
            { return exportPath; }
            else
            { throw new Exception("Export failed"); }
        }

    }
}

