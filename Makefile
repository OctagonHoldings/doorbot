all: guardian report_tag determine_tag_type

guardian: guardian.c
	gcc -o guardian guardian.c -lnfc -lfreefare

report_tag: report_tag.c
	gcc -o report_tag report_tag.c -lnfc -lfreefare

determine_tag_type: determine_tag_type.c
	gcc -o determine_tag_type determine_tag_type.c -lnfc

clean:
	rm report_tag guardian determine_tag_type
