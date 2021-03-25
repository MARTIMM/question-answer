#!/usr/bin/env -S raku -Ilib

# Example taken from C-source shown in gtk3-demo

use v6.d;

#use Gnome::Glib::Main;

use Gnome::Gtk3::Main;
use Gnome::Gtk3::Window;
use Gnome::Gtk3::ProgressBar;
use Gnome::Gtk3::Assistant;
use Gnome::Gtk3::Label;
use Gnome::Gtk3::Entry;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::CheckButton;
use Gnome::Gtk3::Enums;

unit class AssistantHandlers;

#`{{
static GtkWidget *assistant = NULL;
static GtkWidget *progress_bar = NULL;
}}
#my Gnome::Gtk3::Assistant $assistant;
#my Gnome::Gtk3::ProgressBar $progress-bar;

#`{{
static gboolean
apply_changes_gradually (gpointer data)
{
  gdouble fraction;

  /* Work, work, work... */
  fraction = gtk_progress_bar_get_fraction (GTK_PROGRESS_BAR (progress_bar));
  fraction += 0.05;

  if (fraction < 1.0)
    {
      gtk_progress_bar_set_fraction (GTK_PROGRESS_BAR (progress_bar), fraction);
      return G_SOURCE_CONTINUE;
    }
  else
    {
      /* Close automatically once changes are fully applied. */
      gtk_widget_destroy (assistant);
      assistant = NULL;
      return G_SOURCE_REMOVE;
    }
}
}}

method apply_changes_gradually (
  Gnome::Gtk3::ProgressBar $progress-bar --> Bool
) {
  # Work, work, work…
  my Num $fraction = $progress_bar.get-fraction;
  $fraction += 5e-2;

  if $fraction < 1e0 {
    $progress_bar.set-fraction($fraction);
    return True; # continue work
  }

  else {
    # Close automatically once changes are fully applied.
    $assistant.destroy;
    return False; # done and ready
  }
}

#`{{
static void
on_assistant_apply (GtkWidget *widget, gpointer data)
{
  /* Start a timer to simulate changes taking a few seconds to apply. */
  g_timeout_add (100, apply_changes_gradually, NULL);
}
}}

method on_assistant_apply (
  Gnome::Gtk3::Assistant :_widget($assistant),
  Gnome::Gtk3::ProgressBar :$progress-bar
) {
  # Start a timer to simulate changes taking a few seconds to apply. */
  while apply_changes_gradually($progress-bar) { sleep 0.1 }
}

#`{{
static void
on_assistant_close_cancel (GtkWidget *widget, gpointer data)
{
  GtkWidget **assistant = (GtkWidget **) data;

  gtk_widget_destroy (*assistant);
  *assistant = NULL;
}
}}

method on_assistant_close_cancel (
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
  $assistant.destroy;
}

#`{{
static void
on_assistant_prepare (GtkWidget *widget, GtkWidget *page, gpointer data)
{
  gint current_page, n_pages;
  gchar *title;

  current_page = gtk_assistant_get_current_page (GTK_ASSISTANT (widget));
  n_pages = gtk_assistant_get_n_pages (GTK_ASSISTANT (widget));

  title = g_strdup_printf ("Sample assistant (%d of %d)", current_page + 1, n_pages);
  gtk_window_set_title (GTK_WINDOW (widget), title);
  g_free (title);

  /* The fourth page (counting from zero) is the progress page.  The
  * user clicked Apply to get here so we tell the assistant to commit,
  * which means the changes up to this point are permanent and cannot
  * be cancelled or revisited. */
  if (current_page == 3)
      gtk_assistant_commit (GTK_ASSISTANT (widget));
}
}}

method on_assistant_prepare (
  N-GObject $page, # unused
  Gnome::Gtk3::Assistant :_widget($assistant)
) {
  my Int $current_page = $assistant.get-current-page;
  my Int $n_pages = $assistant.get-n-pages;

  $assistant.set-title("Sample assistant ({$current_page + 1} of $n_pages)");

  # The fourth page (counting from zero) is the progress page.  The
  # user clicked Apply to get here so we tell the assistant to commit,
  # which means the changes up to this point are permanent and cannot
  # be cancelled or revisited.
  $assistant.commit if $current_page == 3;
}

#`{{
static void
on_entry_changed (GtkWidget *widget, gpointer data)
{
  GtkAssistant *assistant = GTK_ASSISTANT (data);
  GtkWidget *current_page;
  gint page_number;
  const gchar *text;

  page_number = gtk_assistant_get_current_page (assistant);
  current_page = gtk_assistant_get_nth_page (assistant, page_number);
  text = gtk_entry_get_text (GTK_ENTRY (widget));

  if (text && *text)
    gtk_assistant_set_page_complete (assistant, current_page, TRUE);
  else
    gtk_assistant_set_page_complete (assistant, current_page, FALSE);
}
}}

method on_entry_changed (
  Gnome::Gtk3::Entry :_widget($entry), Gnome::Gtk3::Assistant :$assistant
) {
  $assistant.set-page-complete(
    $assistant.get-nth-page($assistant.get-current-page),
    ? $entry.get-text
  );
}

#`{{
static void
create_page1 (GtkWidget *assistant)
{
  GtkWidget *box, *label, *entry;

  box = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 12);
  gtk_container_set_border_width (GTK_CONTAINER (box), 12);

  label = gtk_label_new ("You must fill out this entry to continue:");
  gtk_box_pack_start (GTK_BOX (box), label, FALSE, FALSE, 0);

  entry = gtk_entry_new ();
  gtk_entry_set_activates_default (GTK_ENTRY (entry), TRUE);
  gtk_widget_set_valign (entry, GTK_ALIGN_CENTER);
  gtk_box_pack_start (GTK_BOX (box), entry, TRUE, TRUE, 0);
  g_signal_connect (G_OBJECT (entry), "changed",
                    G_CALLBACK (on_entry_changed), assistant);

  gtk_widget_show_all (box);
  gtk_assistant_append_page (GTK_ASSISTANT (assistant), box);
  gtk_assistant_set_page_title (GTK_ASSISTANT (assistant), box, "Page 1");
  gtk_assistant_set_page_type (GTK_ASSISTANT (assistant), box, GTK_ASSISTANT_PAGE_INTRO);
}
}}

method create_page1 ( Gnome::Gtk3::Assistant $assistant ) {

  my Gnome::Gtk3::Label $label .= new(
    :text("You must fill out this entry to continue:"
  );

  given my Gnome::Gtk3::Entry $entry .= new {
    .set-activates-default(True);
    .set-valign(GTK_ALIGN_CENTER);
    .register-signal( self, 'on_entry_changed', 'changed', :$assistant);
  }

  given my Gnome::Gtk3::Grid $grid .= new {
    .set-column-spacing(12);
    .set-border-width(12);
    .attach( $label, 0, 0, 1, 1);
    .attach( $entry, 1, 0, 1, 1);
    .show_all;
  }

  $assistant.append-page($grid);
  $assistant.set-page-title( $grid, "Page 1");
  $assistant.set_page_type( $grid, GTK_ASSISTANT_PAGE_INTRO);
}

#`{{
static void
create_page2 (GtkWidget *assistant)
{
  GtkWidget *box, *checkbutton;

  box = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
  gtk_container_set_border_width (GTK_CONTAINER (box), 12);

  checkbutton = gtk_check_button_new_with_label ("This is optional data, you may continue "
                                                 "even if you do not check this");
  gtk_box_pack_start (GTK_BOX (box), checkbutton, FALSE, FALSE, 0);

  gtk_widget_show_all (box);
  gtk_assistant_append_page (GTK_ASSISTANT (assistant), box);
  gtk_assistant_set_page_complete (GTK_ASSISTANT (assistant), box, TRUE);
  gtk_assistant_set_page_title (GTK_ASSISTANT (assistant), box, "Page 2");
}
}}

method create_page2 ( Gnome::Gtk3::Assistant $assistant ) {

  my Gnome::Gtk3::CheckButton $checkbutton .= new( :label(
      "This is optional data, you may continue even if you do not check this"
  ) );

  given my Gnome::Gtk3::Grid $grid .= new {
    .set-column-spacing(12);
    .set-border-width(12);
    .attach( $checkbutton, 0, 0, 1, 1);
    .show_all;
  }

  $assistant.append-page($grid);
  $assistant.set-page-title( $grid, "Page 1");
  $assistant.page-complete( $grid, True);
}

#`{{
static void
create_page3 (GtkWidget *assistant)
{
  GtkWidget *label;

  label = gtk_label_new ("This is a confirmation page, press 'Apply' to apply changes");

  gtk_widget_show (label);
  gtk_assistant_append_page (GTK_ASSISTANT (assistant), label);
  gtk_assistant_set_page_type (GTK_ASSISTANT (assistant), label, GTK_ASSISTANT_PAGE_CONFIRM);
  gtk_assistant_set_page_complete (GTK_ASSISTANT (assistant), label, TRUE);
  gtk_assistant_set_page_title (GTK_ASSISTANT (assistant), label, "Confirmation");
}
}}

method create_page3 ( Gnome::Gtk3::Assistant $assistant ) {

  my Gnome::Gtk3::Label $label .= new(
    :text("This is a confirmation page, press 'Apply' to apply changes")
  );
  $label.show;

  $assistant.append-page($grid);
  $assistant.set-page-title( $grid, "Confirmation");
  $assistant.set_page_type( $grid, GTK_ASSISTANT_PAGE_CONFIRM);
  $assistant.page-complete( $grid, True);
}

#`{{
static void
create_page4 (GtkWidget *assistant)
{
  progress_bar = gtk_progress_bar_new ();
  gtk_widget_set_halign (progress_bar, GTK_ALIGN_CENTER);
  gtk_widget_set_valign (progress_bar, GTK_ALIGN_CENTER);

  gtk_widget_show (progress_bar);
  gtk_assistant_append_page (GTK_ASSISTANT (assistant), progress_bar);
  gtk_assistant_set_page_type (GTK_ASSISTANT (assistant), progress_bar, GTK_ASSISTANT_PAGE_PROGRESS);
  gtk_assistant_set_page_title (GTK_ASSISTANT (assistant), progress_bar, "Applying changes");

  /* This prevents the assistant window from being
   * closed while we're "busy" applying changes.
   */
  gtk_assistant_set_page_complete (GTK_ASSISTANT (assistant), progress_bar, FALSE);
}

GtkWidget*
do_assistant (GtkWidget *do_widget)
{
  if (!assistant)
    {
      assistant = gtk_assistant_new ();

      gtk_window_set_default_size (GTK_WINDOW (assistant), -1, 300);

      gtk_window_set_screen (GTK_WINDOW (assistant),
                             gtk_widget_get_screen (do_widget));

      create_page1 (assistant);
      create_page2 (assistant);
      create_page3 (assistant);
      create_page4 (assistant);

      g_signal_connect (G_OBJECT (assistant), "cancel",
                        G_CALLBACK (on_assistant_close_cancel), &assistant);
      g_signal_connect (G_OBJECT (assistant), "close",
                        G_CALLBACK (on_assistant_close_cancel), &assistant);
      g_signal_connect (G_OBJECT (assistant), "apply",
                        G_CALLBACK (on_assistant_apply), NULL);
      g_signal_connect (G_OBJECT (assistant), "prepare",
                        G_CALLBACK (on_assistant_prepare), NULL);
    }

  if (!gtk_widget_get_visible (assistant))
    gtk_widget_show (assistant);
  else
    {
      gtk_widget_destroy (assistant);
      assistant = NULL;
    }

  return assistant;
}
}}
