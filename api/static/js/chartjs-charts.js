document.addEventListener("DOMContentLoaded", function () {
    const labels = ['Blue', 'Green', 'Red'];
    const colors = {
        Blue: 'rgba(54, 162, 235, 0.2)',
        Green: 'rgba(75, 192, 192, 0.2)',
        Red: 'rgba(255, 99, 132, 0.2)',
    };

    const borderColor = {
        Blue: 'rgba(54, 162, 235, 1)',
        Green: 'rgba(75, 192, 192, 1)',
        Red: 'rgba(255, 99, 132, 1)',
    };

    const victoryPointsElements = document.getElementsByClassName("victoryPointsChart");
    const killsDeathsElements = document.getElementsByClassName("kdChart");

    for (const element of victoryPointsElements) {
        const victoryPointData = JSON.parse(element.getAttribute("data-json"));

        new Chart(element, {
            type: "bar",
            data: {
                labels: labels,
                datasets: [{
                    label: 'Victory Points',
                    data: labels.map(color => victoryPointData[color.toLowerCase()]),
                    backgroundColor: labels.map(color => colors[color]),
                    borderColor: labels.map(color => borderColor[color]),
                    borderWidth: 1,
                }],
            },
            options: {
                title: {
                    display: true,
                    text: 'Victory Points'
                },
                scales: {
                    y: {beginAtZero: true}
                }
            }
        });
    }

    for (const element of killsDeathsElements) {
        const killsDeathsData = JSON.parse(element.getAttribute("data-json"));
        const kdRatios = {
            "blue": killsDeathsData[0].blue / killsDeathsData[1].blue,
            "green": killsDeathsData[0].green / killsDeathsData[1].green,
            "red": killsDeathsData[0].red / killsDeathsData[1].red
        };

        new Chart(element, {
            type: "pie",
            data: {
                labels: ['Blue', 'Green', 'Red'],
                datasets: [{
                    label: 'K/D Ratio',
                    data: [kdRatios.blue, kdRatios.green, kdRatios.red],
                    backgroundColor: ['rgba(75, 192, 192, 0.2)', 'rgba(75, 192, 75, 0.2)', 'rgba(255, 99, 132, 0.2)'],
                    borderColor: ['rgba(75, 192, 192, 1)', 'rgba(75, 192, 75, 1)', 'rgba(255, 99, 132, 1)'],
                    borderWidth: 1
                }]
            },
            options: {
                plugins: {
                    title: {
                        display: true,
                        text: 'K/D Ratio'
                    }
                }
            }
        });
    }


}); // end of dom load event listener