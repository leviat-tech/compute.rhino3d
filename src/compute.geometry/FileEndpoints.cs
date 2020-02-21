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
            Post["convert/{extension}"] = _ => Convert(Context, _["extension"]);
        }

        static Response Convert(NancyContext ctx, string extension)
        {
            string requestId = ctx.Request.Headers["X-Compute-Id"].FirstOrDefault() as string;
            var stashDir = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "Compute", "Requests");
            string attachmentDir = Path.Combine(stashDir, requestId);
            DirectoryInfo d = new DirectoryInfo(attachmentDir);
            FileInfo[] attachments = d.GetFiles("*.*");
            var firstAttachment = attachments.FirstOrDefault();

            if (firstAttachment == null)
                throw new Exception("No attachment found.");

            var doc = ImportAny(firstAttachment.FullName);

            string outputPath;
            switch (extension.ToLower())
            {
                case "3dm":
                    outputPath = doc.Path;
                    doc.Dispose();
                    break;
                case "stp":
                    outputPath = ExportStep(doc, "stp");
                    break;
                default:
                    outputPath = ExportAny(doc, extension.ToLower());
                    break;
            }

            var outputFile = new FileStream(outputPath, FileMode.Open);
            var response = new StreamResponse(() => outputFile, MimeTypes.GetMimeType(Path.GetFileName(outputPath)));
            return response.AsAttachment(Path.GetFileName(outputPath));
        }



        static Rhino.RhinoDoc ImportAny(string source)
        {
            string sourceExtension = Path.GetExtension(source);
            Rhino.RhinoDoc doc;
            switch (sourceExtension.ToLower())
            {
                case "3dm":
                    doc = Rhino.RhinoDoc.Load(source);
                    break;
                default:
                    doc = Rhino.RhinoDoc.New("");
                    doc.Import(source);
                    doc.SaveAs(Path.ChangeExtension(source, "3dm"));
                    doc.Dispose();
                    doc = Rhino.RhinoDoc.Load(Path.ChangeExtension(source, "3dm"));
                    break;
            }
            return doc;
        }

        static string ExportStep(Rhino.RhinoDoc doc, string extension)
        {
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
        static string ExportAny(Rhino.RhinoDoc doc, string extension)
        {
            string docPath = doc.Path;
            string exportPath = Path.ChangeExtension(docPath, extension);
            bool exported = doc.Export(exportPath);
            doc.Dispose();
            if (exported)
            { return exportPath; }
            else
            { throw new Exception("Export failed"); }
        }

    }
}

