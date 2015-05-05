
SRC=DP4
NAME=diplomka

$(NAME): clean
	swipl -G4g -T500m -L500m -q -g prolog -o $(NAME) -c $(SRC).pl

clean:
	rm -f *.hi *.o $(NAME) *.exe *~


