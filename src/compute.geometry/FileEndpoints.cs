using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using Nancy;
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
            string jsonString = string.Empty;
            using (var reader = new StreamReader(ctx.Request.Body))
            {
                jsonString = reader.ReadToEnd();
            }
            object data = string.IsNullOrWhiteSpace(jsonString) ? null : JsonConvert.DeserializeObject(jsonString);
            var ja = data as Newtonsoft.Json.Linq.JArray;

            //string resultString = HandlePostHelper(ja, returnModifiers);

            var sourcePath = @"C:\Users\mkarimi\Desktop\compute-python\box.3dm";
            var doc =  Rhino.RhinoDoc.Load(sourcePath);
            var step = Rhino.FileIO.FileStp.Write(@"C:\Users\mkarimi\Desktop\compute-python\box.stp", doc, new Rhino.FileIO.FileStpWriteOptions() );
            var response = (Nancy.Response)Newtonsoft.Json.JsonConvert.SerializeObject(DateTime.UtcNow);
            response.ContentType = "application/json";
            return response;
        }

    }
}

