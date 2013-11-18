name             'discourse'
maintainer       'marsam'
maintainer_email 'rodasmario2@gmail.com'
license          'WTFPL'
description      'Installs/Configures discourse'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'apt'
depends 'git', '> 2.6.0'
depends 'nginx', '> 1.8.0'
depends 'rbenv', '> 1.6.5'
depends 'postfix', '> 3.0.0'
depends 'postgresql', '> 3.0.4'
depends 'supervisor', '> 0.4.8'
depends 'build-essential'

supports 'ubuntu'
