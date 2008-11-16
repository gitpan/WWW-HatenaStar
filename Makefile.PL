use inc::Module::Install;
name 'WWW-HatenaStar';
all_from 'lib/WWW/HatenaStar.pm';

requires $_ for (qw/
    URI
    WWW::Mechanize
    JSON::Syck
/);

requires WWW::HatenaLogin => 0.02;

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;