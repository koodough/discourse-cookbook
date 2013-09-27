name             'discourse'
maintainer       'marsam'
maintainer_email 'rodasmario2@gmail.com'
license          'WTFPL'
description      'Installs/Configures discourse'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'apt'
depends 'git'
depends 'nginx'
depends 'rbenv'
depends 'postfix'
depends 'database'
depends 'postgresql'

supports 'ubuntu'
