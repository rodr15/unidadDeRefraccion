import 'package:flutter/material.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  

  @override
  initState() {
    super.initState();

    
  }


  /* Variables de los botones */
  bool lamparaState = false;
  bool aux1State = false;
  bool aux2State = false;
  bool sillaState = false;

  @override
  Widget build(BuildContext context) {
    /* Variables de la pantalla */
    double sh = MediaQuery.of(context).size.height;
    double sw = MediaQuery.of(context).size.width;
    FloatingActionButton lampara = FloatingActionButton(
      child: const Icon(Icons.light),
      backgroundColor: lamparaState ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          lamparaState = !lamparaState;
          
        });
     
      },
    );
    FloatingActionButton Aux1 = FloatingActionButton(
      child: const Icon(Icons.electrical_services),
      backgroundColor: aux1State ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          aux1State = !aux1State;
        });
      },
    );
    FloatingActionButton Aux2 = FloatingActionButton(
      child: const Icon(Icons.electrical_services),
      backgroundColor: aux2State ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          aux2State = !aux2State;
        });
      },
    );
    FloatingActionButton Silla = FloatingActionButton(
      child: const Icon(Icons.chair_alt_outlined),
      backgroundColor: sillaState ? Colors.green : Colors.red,
      onPressed: () {
        setState(() {
          sillaState = !sillaState;
        });
      },
    );
    Row Navigate = Row(
      children: [
        const Spacer(flex: 2),
        lampara,
        const Spacer(),
        Aux1,
        const Spacer(),
        Aux2,
        const Spacer(),
        Silla,
        const Spacer(flex: 2),
      ],
    );

    FloatingActionButton sillaArriba = FloatingActionButton(
      child: const Icon(Icons.arrow_upward),
      backgroundColor: Colors.amber,
      onPressed: () {},
    );
    FloatingActionButton sillaAbajo = FloatingActionButton(
      child: const Icon(Icons.arrow_downward),
      backgroundColor: Colors.amber,
      onPressed: () {},
    );

    Padding botonesSilla = Padding(
      padding: EdgeInsets.only(left: sw - 60),
      child: Column(
        children: [
          const Spacer(flex: 10),
          sillaArriba,
          const Spacer(),
          sillaAbajo,
          const Spacer(flex: 10),
        ],
      ),
    );

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: Navigate,
        body: Stack(children: [
          Center(
            child: Container(
              color: Colors.blue,
              width: sw - 20,
              height: sh - 1.5 * sh / 10,
              
            ),
          ),
          if (sillaState) botonesSilla
        ]),
      ),
    );
  }
}
