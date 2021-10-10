use v6.d;

#-------------------------------------------------------------------------------
unit class QA::Status:auth<github:MARTIMM>:ver<0.1.0>;

#-------------------------------------------------------------------------------
my QA::Status $instance;
has Supplier $!supplier;

has Hash $!faulty-states;

#-------------------------------------------------------------------------------
method new ( ) { !!! }

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  $!supplier .= new;
  $!faulty-states = %();
}

#-------------------------------------------------------------------------------
method instance ( |c --> QA::Status ) {
  $instance //= self.bless(|c);

  $instance
}

#-------------------------------------------------------------------------------
method tap ( Callable $c ) {
  my $supply = $!supplier.Supply;
  $supply.tap(&$c);
}

#-------------------------------------------------------------------------------
method send ( Any $v ) {
  $!supplier.emit($v);
}

#-------------------------------------------------------------------------------
method set-faulty-state ( Str $name, Bool:D $faulty-state ) {
  $!faulty-states{$name} = $faulty-state;
  $!supplier.emit(%(:state(self.faulty-state)));
}

#-------------------------------------------------------------------------------
method get-faulty-state ( Str $name --> Bool ) {
  $!faulty-states{$name} // False;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 faulty-state

Return overall faulty state. It is the or-ed value of all states noted in this object.

  method faulty-state ( --> Bool )
=end pod
#TS:2:faulty-state
method faulty-state ( --> Bool ) {
  [or] $!faulty-states.values;
}
