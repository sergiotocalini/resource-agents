Name:			resource-agents-sergiotocalini
Version:		9999
Release:		1%{?dist}
License:		GPLv2
Summary:		OCF resource agent for Pacemaker
Group:			System Environment/Base
URL:			https://github.com/sergiotocalini/resource-agents/archive/master.zip
BuildArch:		noarch
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-root
Requires:		resource-agents

%description
This package contains the OCF-compliant resource agents for Pacemaker.

%clean

%files
%defattr(755,root,root,-)
%dir		/usr/lib/ocf/resource.d/sergiotocalini
		/usr/lib/ocf/resource.d/sergiotocalini/*
%dir		/usr/lib/ocf/lib/sergiotocalini
		/usr/lib/ocf/lib/sergiotocalini/*
		

%changelog
* Thu Jun 26 2014  <sergiotocalini@gmail.com> - resource-agents-sergiotocalini-9999-1
- Initial repository.
