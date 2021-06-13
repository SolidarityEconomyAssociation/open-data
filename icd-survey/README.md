# TITLE

icd-survey: Generates content for the survey.solidarityeconomy.coop website.

# PREREQUISITES

RunRequires Ruby 2.x+, and the Ruby Bundler tool. Also Bash, scp, and
the usual Unix toolchain (cp, mv, etc.).

# GENERATION

As this is a very early draft created fairly briskly for International
Co-operatives Day 2021, various parameters are currently hardwired,
and there is an assumption that the [icd-survey][] project (containing the
website content) is checked out as a sibling to this (`open-data`) project.

You may need to change some parameters.  Certainly you should inspect
the scripts and understand their purpose.

Then, to generate:

    bundle install
	bundle exec ./rebuild.sh


Deployment is then a matter of committing the new data, pushing it,
and pulling the repository checked out on the web server.

[icd-survey]: https://github.com/SolidarityEconomyAssociation/icd-survey
