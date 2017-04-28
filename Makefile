MAINFILE	:= report

BUILDDIR	:= build

INPUTFILES	:= scripts/* tables/*
TEXFILES	:= *.tex
BIBFILES	:= *.bib

.PHONY: all clean new view quick

all: report

clean:
	rm -rf ${BUILDDIR}

new: clean all

report: ${BUILDDIR}/${MAINFILE}.pdf
	cp ${BUILDDIR}/${MAINFILE}.pdf ${MAINFILE}.pdf

view: report
	evince ${MAINFILE}.pdf &

quick: ${TEXFILES}
	-mkdir ${BUILDDIR}
	pdflatex -output-directory ${BUILDDIR} ${MAINFILE}.tex


${BUILDDIR}/${MAINFILE}.pdf: ${TEXFILES} ${BIBFILES} ${INPUTFILES}
	-mkdir ${BUILDDIR}
	pdflatex -output-directory ${BUILDDIR} ${MAINFILE}.tex
	pdflatex -output-directory ${BUILDDIR} ${MAINFILE}.tex
	bibtex ${BUILDDIR}/${MAINFILE}
	bibtex ${BUILDDIR}/${MAINFILE}
	pdflatex -output-directory ${BUILDDIR} ${MAINFILE}.tex
	pdflatex -output-directory ${BUILDDIR} ${MAINFILE}.tex

