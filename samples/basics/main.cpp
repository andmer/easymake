// File: main.cpp

#include <iostream>

#include "math/add.h"

using namespace std;

int main(){
	cout<<"please enter two integer:"<<endl;

	int a,b;
	cin>>a>>b;

	cout<<"add("<<a<<","<<b<<") returns "<<add(a,b)<<endl;
}
