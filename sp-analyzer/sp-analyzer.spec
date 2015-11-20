Name:		sp-analyzer
Version:	0
Release:	2
Summary:	Tool for generating EMC Storage Processor (SP) stats
Group:		System Environment/Shells
License:	GPL
Source0:	%{name}-%{version}-%{release}.tar.gz
#BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)
BuildArch:	noarch
Requires:	python
Packager:	%{packager}
Vendor:		rkferreira

%define _rpmfilename %%{name}-%%{version}-%%{release}.%%{arch}.rpm
%define _prefix /usr/local/bin

%description
Contains script that interacts with SP for monitoring data.


%prep
%setup -n %{name}


%build


%install
%{__rm} -rf %{buildroot}
%{__install} -m 0755 -d    %{buildroot}%{_prefix}
%{__install} -m 0644 -d    %{buildroot}/tmp/monitoring/
%{__install} -m 0755 *.py  %{buildroot}%{_prefix}/
if [ -d %{buildroot}/etc/cron.d ]
then
	echo "etc and cron.d already exists"
else
	%{__install} -m 0766 -d %{buildroot}/etc/cron.d
fi
%{__install} -m 0644 etc/*.cfg  %{buildroot}/etc/sp-analyzer.cfg
%{__install} -m 0644 etc/cron.d/*.cron  %{buildroot}/etc/cron.d/sp-analyzer.cron

%clean
rm -rf %{buildroot}
rm -rf $RPM_BUILD_ROOT $RPM_BUILD_DIR/%{name} $RPM_SOURCE_DIR/%{name}-%{version}-%{release}.tar.gz


%files
%defattr(0644,root,root)
%config(noreplace) /etc/*.cfg
%config(noreplace) /etc/cron.d/*.cron
%attr(0755,root,root) %{_prefix}/*


%changelog
* Mon Sep 22 2014 Rodrigo Kellermann Ferreira <rkferreira@gmail.com>
- Creation of SP monitoring
