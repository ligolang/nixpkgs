{ lib
, python310
, fetchFromGitHub
, gdk-pixbuf
, gnome
, gpsbabel
, glib-networking
, glibcLocales
, gobject-introspection
, gtk3
, perl
, sqlite
, tzdata
, webkitgtk
, wrapGAppsHook
, xvfb-run
}:

let
  python = python310.override {
    packageOverrides = (self: super: {
      matplotlib = super.matplotlib.override {
        enableGtk3 = true;
      };
      sqlalchemy = super.sqlalchemy.overridePythonAttrs (old: rec {
        version = "1.4.46";
        src = self.fetchPypi {
          pname = "SQLAlchemy";
          inherit version;
          hash = "sha256-aRO4JH2KKS74MVFipRkx4rQM6RaB8bbxj2lwRSAMSjA=";
        };
      });
    });
  };
in python.pkgs.buildPythonApplication rec {
  pname = "pytrainer";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "pytrainer";
    repo = "pytrainer";
    rev = "v${version}";
    sha256 = "sha256-U2SVQKkr5HF7LB0WuCZ1xc7TljISjCNO26QUDGR+W/4=";
  };

  propagatedBuildInputs = with python.pkgs; [
    sqlalchemy-migrate
    python-dateutil
    matplotlib
    lxml
    setuptools
    requests
    gdal
  ];

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook
  ];

  buildInputs = [
    sqlite
    gtk3
    webkitgtk
    glib-networking
    gnome.adwaita-icon-theme
    gdk-pixbuf
  ];

  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ perl gpsbabel ])
  ];

  nativeCheckInputs = [
    glibcLocales
    perl
    xvfb-run
  ] ++ (with python.pkgs; [
    mysqlclient
    psycopg2
  ]);

  checkPhase = ''
    env HOME=$TEMPDIR TZDIR=${tzdata}/share/zoneinfo \
      TZ=Europe/Kaliningrad \
      LC_ALL=en_US.UTF-8 \
      xvfb-run -s '-screen 0 800x600x24' \
      ${python.interpreter} setup.py test
  '';

  meta = with lib; {
    homepage = "https://github.com/pytrainer/pytrainer";
    description = "Application for logging and graphing sporting excursions";
    maintainers = with maintainers; [ rycee dotlambda ];
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
