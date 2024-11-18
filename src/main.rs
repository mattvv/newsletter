use std::net::TcpListener;

use newsletter::configuration::get_configuration;
use newsletter::startup::run;
use newsletter::telemetry::{get_subscriber, init_subscriber};
use sqlx::PgPool;

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    let susbcriber = get_subscriber("newsletter".into(), "info".into(), std::io::stdout);
    init_subscriber(susbcriber);

    let configuration = get_configuration().expect("Failed to read configuration.");
    let address = format!(
        "{}:{}",
        configuration.application.host, configuration.application.port
    );
    let connection_pool = PgPool::connect_lazy(&configuration.database.connection_string())
        .expect("Failed to connect to Postgres.");

    let listener = TcpListener::bind(address)?;
    run(listener, connection_pool)?.await
}
