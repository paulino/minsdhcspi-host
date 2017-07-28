.PHONY:	clean
FIGURES := $(shell ls *.odg )
FIGURES_EPS := $(FIGURES:%.odg=%.eps)
FIGURES_PDF := $(FIGURES:%.odg=%-eps-converted-to.pdf)


all: minsdhcspi-host.pdf

minsdhcspi-host.pdf: $(FIGURES_EPS) minsdhcspi-host.tex 
	pdflatex -shell-escape minsdhcspi-host.tex ; pdflatex -shell-escape minsdhcspi-host.tex

%.eps:	%.odg
	soffice  --invisible --convert-to eps $<

clean:
	rm -f $(FIGURES_EPS) *.aux $(FIGURES_PDF)
	rm -f minsdhcspi-host.log minsdhcspi-host.out
