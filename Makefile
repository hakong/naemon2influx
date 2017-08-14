NAME=		naemon2influx
VERSION=	1.0
RELEASE=	03

RPM=		${HOME}/rpmbuild/RPMS/x86_64/${NAME}-${VERSION}-${RELEASE}.el7.x86_64.rpm
DEB=		${NAME}-${VERSION}-${RELEASE}.deb

BUILD=		${NAME}-${VERSION}-${RELEASE}
DEBIAN=		${BUILD}/DEBIAN
SPEC=		${NAME}.spec
TMPL=		${NAME}.tmpl

all:	deb rpm

clean:
	@rm -rf ${SPEC} ${RPM} ${DEB} naemon2influx.1.gz naemon2influx.cfg.5.gz ${BUILD}

${RPM}: ${SPEC}
	@echo "Building ${NAME} rpm ..."
	@rm -f ${RPM}
	@rpmbuild -bb ${SPEC}

${SPEC}:	${TMPL} ${MAKEFILE}
	@sed -s 's/__NAME__/${NAME}/g;s/__RELEASE__/${RELEASE}/g;s/__VERSION__/${VERSION}/g;' ${TMPL} > ${SPEC}
rpm:	${RPM}
deb:	${DEB}

install:
	@pod2man naemon2influx | gzip > /usr/share/man/man1/naemon2influx.1.gz
	@pod2man --section 5 naemon2influx.cfg.pod | gzip > /usr/share/man/man5/naemon2influx.cfg.5.gz
	@install -m 0755 naemon-perf /usr/bin
	@install -m 0755 naemon2influx /usr/bin
	@install -m 0640 naemon2influx.cfg /etc/naemon

${BUILD}:
	@mkdir -p ${NAME}-${VERSION}-${RELEASE}

${DEBIAN}: ${BUILD}
	@mkdir -p ${DEBIAN}

${DEB}:	${DEBIAN} control naemon2influx.cfg naemon2influx.cfg.pod naemon2influx
	@sed -s 's/__NAME__/${NAME}/g;s/__RELEASE__/${RELEASE}/g;s/__VERSION__/${VERSION}/g;' control > ${DEBIAN}/control
	@echo /etc/naemon/naemon2influx.cfg > ${DEBIAN}/conffiles
	@mkdir -p ${BUILD}/usr/bin ${BUILD}/etc/naemon ${BUILD}/usr/share/man/man1 ${BUILD}/usr/share/man/man5
	@install -m 0755 naemon-perf ${BUILD}/usr/bin
	@install -m 0755 naemon2influx ${BUILD}/usr/bin
	@install -m 0640 naemon2influx.cfg ${BUILD}/etc/naemon
	@pod2man naemon2influx | gzip > ${BUILD}/usr/share/man/man1/naemon2influx.1.gz
	@pod2man --section 5 naemon2influx.cfg.pod | gzip > ${BUILD}/usr/share/man/man5/naemon2influx.cfg.5.gz
	@dpkg-deb --build ${BUILD}
	@rm -rf ${BUILD}
