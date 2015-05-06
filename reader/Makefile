all: report_tag determine_tag_type

report_tag: report_tag.c
	gcc -o report_tag report_tag.c -lnfc -lfreefare

determine_tag_type: determine_tag_type.c
	gcc -o determine_tag_type determine_tag_type.c -lnfc

.PHONY: clean
clean:
	rm report_tag determine_tag_type
