import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
  if (req.method === "OPTIONS") return new Response("ok",{headers:corsHeaders});

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const admin = createClient(supabaseUrl, serviceRole);

  try {
    const authHeader=req.headers.get("Authorization");
    if(!authHeader) return new Response(JSON.stringify({error:"Missing authorization"}),{status:401,headers:{...corsHeaders,"Content-Type":"application/json"}});
    const jwt=authHeader.replace("Bearer ","");
    const {data:callerData,error:callerError}=await admin.auth.getUser(jwt);
    if(callerError||!callerData.user) return new Response(JSON.stringify({error:"Invalid session"}),{status:401,headers:{...corsHeaders,"Content-Type":"application/json"}});

    const {data:manager}=await admin.from("maintenance_users").select("role,is_active").eq("auth_user_id",callerData.user.id).maybeSingle();
    if(!manager||!manager.is_active||manager.role!=="manager") return new Response(JSON.stringify({error:"Manager permission required"}),{status:403,headers:{...corsHeaders,"Content-Type":"application/json"}});

    const body=await req.json();
    const full_name=String(body.full_name||"").trim();
    const email=String(body.email||"").trim().toLowerCase();
    const password=String(body.password||"");
    const role=String(body.role||"employee");
    const specialty=body.specialty?String(body.specialty).trim():null;

    if(!full_name||!email||password.length<6) return new Response(JSON.stringify({error:"Name, email and password (6+ chars) are required"}),{status:400,headers:{...corsHeaders,"Content-Type":"application/json"}});
    if(!["employee","chamber","technician","manager"].includes(role)) return new Response(JSON.stringify({error:"Invalid role"}),{status:400,headers:{...corsHeaders,"Content-Type":"application/json"}});

    const {data:created,error:createError}=await admin.auth.admin.createUser({email,password,email_confirm:true});
    if(createError) return new Response(JSON.stringify({error:createError.message}),{status:400,headers:{...corsHeaders,"Content-Type":"application/json"}});

    const {error:profileError}=await admin.from("maintenance_users").insert({
      full_name,email,role,specialty,is_active:true,auth_user_id:created.user.id
    });

    if(profileError){
      await admin.auth.admin.deleteUser(created.user.id);
      return new Response(JSON.stringify({error:profileError.message}),{status:400,headers:{...corsHeaders,"Content-Type":"application/json"}});
    }

    return new Response(JSON.stringify({ok:true}),{status:200,headers:{...corsHeaders,"Content-Type":"application/json"}});
  } catch(e) {
    return new Response(JSON.stringify({error:e.message||"Unexpected error"}),{status:500,headers:{...corsHeaders,"Content-Type":"application/json"}});
  }
});
