#tl:1:QA::Gui::SheetWindow
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Box;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Dialog;

use QA::Types;
use QA::Status;

use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::SheetTools;
#use QA::Gui::QALabel;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::SheetSimpleWindow

=end pod

unit class QA::Gui::SheetSimpleWindow:auth<github:MARTIMM>;
also does QA::Gui::SheetTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;
has Int $!response;
has Gnome::Gtk3::Widget $!widget;
has Any $!result-handler-object;
has Str $!result-handler-method;

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!sheet-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
  Gnome::Gtk3::Widget :$!widget,
  Any :$!result-handler-object?, Str :$!result-handler-method?
) {
  $!sheet .= new(:$!sheet-name);
  self.load-user-data($user-data);
  self.set-style('QASheetSimple');

  # todo width and height spec must go to sets
  with $!sheet {
    $!widget.set-border-width(2);
    $!widget.set-size-request( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  self.set-grid($!widget);
  self.set-grid-content($!widget);

  # add some buttons specific for this notebook
  with my Gnome::Gtk3::Grid $button-grid .= new {
    with my Gnome::Gtk3::Box $strut .= new {
      .set-hexpand(True);
      .set-vexpand(False);
      .set-halign(GTK_ALIGN_START);
      .set-valign(GTK_ALIGN_START);
      .set-margin-top(0);
      .set-margin-start(0);
    }
    .attach( $strut, 0, 0, 1, 1);

    .attach(
      self.create-button(
        'cancel', :method-object(self), :method-name<cancel-response>
      ), 1, 0, 1, 1
    );

    .attach(
      self.create-button(
        'finish', :method-object(self), :method-name<ok-response>
      ), 2, 0, 1, 1
    );
  }
  $!grid.attach( $button-grid, 0, 2, 1, 1);

  QA::Status.instance.clear-status;
}

#-------------------------------------------------------------------------------
method cancel-response ( ) {
  note 'cancel-response';

  if self.show-cancel {
    $!widget.destroy;
  }
}

#-------------------------------------------------------------------------------
method ok-response ( ) {
  note 'ok-response';

  my QA::Status $status .= instance;

  if $status.faulty-state {
    my QA::Gui::OkMsgDialog $ok .= new(
      :message(
        "There are still missing or wrong answers, cannot save data"
      )
    );

    $ok.dialog-run;
    $ok.destroy;
  }

  else {
    self.save-data;

    if ?$!result-handler-object and
        $!result-handler-object.^can($!result-handler-method) {
      $!result-handler-object."$!result-handler-method"(
        $!result-user-data
      );
    }

    # must hide instead of destroy, otherwise the return status
    # is set to GTK_RESPONSE_NONE
    $!widget.destroy;
  }
}

#-------------------------------------------------------------------------------
method show-sheet ( ) {
  $!widget.show-all;
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {
  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.dialog-run);
    $yn.destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}
