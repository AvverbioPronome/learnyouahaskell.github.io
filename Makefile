##
# Build LYAH web site from Markdown sources using Pandoc and sed
#

all: site

site:
	cd markdown && ./generate.sh

epub:
	cd markdown && ./generate_epub.sh
clean:
	find ./docs -name '*.html' -not -name 'index.html' -delete

# end
