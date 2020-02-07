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
            Post["exportstep"] = _ => ExportStep(Context);
        }

        static Response ExportStep(NancyContext ctx)
        {
            string cache = @"C:\Users\mkarimi\Desktop\compute-python\incoming";
            //var a = Rhino.RhinoDoc.New("abc");
            //a.Objects.Add(a)

            var file = ctx.Request.Files.FirstOrDefault();

            if (file == null)
                throw new Exception("No attachment found.");
            try
            {
                string path = Path.Combine(cache, file.Name);
                using (FileStream output = new FileStream(path, FileMode.Create))
                {
                    file.Value.CopyTo(output);
                }
                var doc = Rhino.RhinoDoc.Load(path);
                var step = Rhino.FileIO.FileStp.Write(Path.ChangeExtension(path,"stp"), doc, new Rhino.FileIO.FileStpWriteOptions());
                doc.Dispose();
                    
                var outputFile = new FileStream(Path.ChangeExtension(path, "stp"), FileMode.Open);
                var outputName = Path.ChangeExtension(file.Name, "stp");

                var response = new StreamResponse(() => outputFile, MimeTypes.GetMimeType(outputName));
                return response.AsAttachment(outputName);
            }
            catch (Exception e)
            {
                throw;
            }
        }

    }
}

